require 'resolv'

module Iqeo

  class HostspecException < Exception ; end

  class Hostspec

    VERSION = '0.0.1'

    include Enumerable

    attr_reader :string, :mask, :mask_length, :address_spec, :hostname

    def initialize spec_str
      @string = spec_str
      raise HostspecException, 'spec cannot be empty' if spec_str.empty?
      host_str, mask_str = split_on_slash spec_str
      raise HostspecException, 'host cannot be empty' if host_str.empty?
      parse_mask mask_str
      begin
        parse_address_spec host_str
      rescue HostspecException
        parse_hostname host_str
      end
      raise HostspecException, 'complex spec cannot have mask length' if @mask_specified && @address_spec.any? { |octet| octet.size > 1 }
      mask_address_spec
    end

    def split_on_slash str
      case str.count '/'
      when 0 then [ str.strip, '' ]
      when 1 then str.strip.split '/'
      else raise 'bad format, expected 0 or 1 "/"'
      end
    end

    def parse_mask str
      if str.empty?
        @mask = '255.255.255.255'
        @mask_length = 32
        @mask_specified = false
        return
      end
      if match = str.match( /^\d+$/ )
        @mask_length = match[0].to_i
        raise "bad mask length (#{@mask_length}), expected between 0 ad 32" unless @mask_length.between? 0,32
        mask_int = ((2**@mask_length)-1) << (32-@mask_length)
        @mask = [24,16,8,0].collect { |n| ( mask_int & ( 255 << n ) ) >> n }.join '.'
        @mask_specified = true
      else
        raise "bad format, expected mask length after '/'"
      end
    end

    def mask_address_spec
      @address_spec.each_with_index do |octet,index|
        high_bit_position = ( index * 8 ) + 1 
        low_bit_position = ( index + 1 ) * 8
        @address_spec[index] = case
        when @mask_length >= low_bit_position then octet
        when @mask_length < high_bit_position then [0..255]
        else
          octet_mask_length = @mask_length % 8
          octet_mask = ( ( 2 ** octet_mask_length ) - 1 ) << ( 8 - octet_mask_length )
          octet_mask_inverted = octet_mask ^ 255
          octet_min = octet_mask & octet[0]
          octet_max = octet_min | octet_mask_inverted
          [octet_min..octet_max]
        end
      end
    end

    def parse_address_spec str
      octet_strs = str.split '.'
      raise HostspecException, 'bad ip, expected 4 octets' unless octet_strs.size == 4    
      octets = octet_strs.collect { |octet_str| parse_octet octet_str }
      @address_spec = octets
    end

    def parse_octet str
      values = str.split ','
      values.collect { |value_str| parse_octet_value value_str }
    end

    def parse_octet_value str
      # values may be dash denoted ranges, possibilities...
      #   n   : just a number         :   'n'.split '-' == ['n']       <= same = problem!    'n'.split '-', -1 == [ "n"       ] 
      #   n-m : range from n to m     : 'n-m'.split '-' == ['n','m']                       'n-m'.split '-', -1 == [ "n" , "m" ]
      #   n-  : range from n to 255   :  'n-'.split '-' == ['n']       <= same = problem!   'n-'.split '-', -1 == [ "n" , ""  ]
      #   -m  : range from 0 to m     :  '-m'.split '-' == ['','m']                         '-m'.split '-', -1 == [ ""  , "m" ]
      #   -   : range from 0 to 255   :   '-'.split '-' == []                                '-'.split '-', -1 == [ ""  , ""  ]
      numbers = str.split '-', -1 # maximize return fields to distinguish 'n' from '-m'
      case numbers.size
      when 1 then
        check_octet_value numbers[0]
        numbers[0].to_i
      when 2 then
        numbers[0] =   '0' if numbers[0].empty?
        numbers[1] = '255' if numbers[1].empty?
        check_octet_value numbers[0]
        check_octet_value numbers[1]
        range_start = numbers[0].to_i
        range_finish = numbers[1].to_i
        raise HostspecException, "bad ip, reversed range in octet value: #{str}" if range_start > range_finish
        range_start..range_finish
      else
        raise HostspecException, "bad ip, invalid octet value: #{str}"
      end
    end

    def check_octet_value str
      match = str.match /^(25[0-5]|2[0-4]\d|[0-1]\d\d|\d\d|\d)$/
      raise HostspecException, "bad ip, octet value is not a number in 0-255: #{str}" unless match
    end

    def parse_hostname str
      @hostname = str
      parse_address_spec Resolv.getaddress(str)
    end

    def recursively_iterate_octets octet_index = 0, address = [], &block
      @address_spec[octet_index].each do |item|
        if item.respond_to? :each
          item.each do |value|
            address.push value
            octet_index == 3 ? yield( address.join '.' ) : recursively_iterate_octets( octet_index + 1, address, &block )
            address.pop
          end
        else
          address.push item
          octet_index == 3 ? yield( address.join '.' ) : recursively_iterate_octets( octet_index + 1, address, &block )
          address.pop
        end
      end
    end

    def each_address 
      if block_given?
        recursively_iterate_octets do |address_str|
          yield address_str
        end
      else
        return to_enum( :each_address ) { size }
      end
    end
  
    alias_method :each, :each_address

    def size
      if @mask_length == 32
        @address_spec.inject(1) { |oc,o| oc * o.inject(0) { |vc,v| vc + ( v.respond_to?(:each) ? v.size : 1 ) } }
      else
        2**(32-@mask_length)
      end
    end

    def min
      first
    end

    def last
      address = nil
      each { |addr| address = addr }
      address
    end

    def max
      last
    end

    def minmax
      [first,last]
    end

  end

end


