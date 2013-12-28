#!/usr/bin/env ruby

# nmap compatible host specs
# eg: scanme.nmap.org 192.168.0.0/8 10.0.0,1,3-7.-
#  hostname : not an IP address
#  ip : an IP address
#  hostname/ip + cidr : /n suffix
#  ip w/ranges : ip with ranges specifed by '-' & ',' 

module Iqeo

  class HostspecException < Exception ; end

  class Hostspec

    VERSION = '0.0.1'

    attr_reader :string, :mask, :mask_length, :mask_int, :address_spec, :hostname

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
        @mask_int = 4294967295
        return
      end
      if match = str.match( /^\d+$/ )
        @mask_length = match[0].to_i
        raise "bad mask length (#{@mask_length}), expected between 0 ad 32" unless @mask_length.between? 0,32
        @mask_int = ((2**@mask_length)-1) << (32-@mask_length)
        @mask = [24,16,8,0].collect { |n| ( @mask_int & ( 255 << n ) ) >> n }.join '.'
      else
        raise "bad format, expected mask length after '/'"
      end
    end

    def parse_address_spec str
      octet_strs = str.split '.'
      raise HostspecException, 'bad ip, expected 4 octets' unless octet_strs.size == 4    
      octets = octet_strs.collect { |octet_str| parse_octet octet_str }
      #@address_int = octets.reverse.collect.each_with_index { |octet,i| octet*(2**(i*8)) }.inject(:+)
      @address_spec = octets
    end

    def parse_octet str
      # octets may have multiple comma separated values
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
        number = numbers[0]
        match = number.match /^(25[0-5]|2[0-4]\d|[0-1]\d\d|\d\d|\d)$/
        raise HostspecException, 'bad ip, invalid octet' unless match
        number.to_i
      when 2 then
        numbers[0] =   '0' if numbers[0].empty?
        numbers[1] = '255' if numbers[1].empty?
        numbers[0].to_i..numbers[1].to_i
      else
        raise HostspecException, 'bad ip, invalid octet'
      end
    end

    def parse_hostname str
      @hostname = str
      parse_address_spec Resolv.getaddress(str)
    end

    def each_address
      addresses_octets = @address_spec[0].product(@address_spec[1],@address_spec[2],@address_spec[3])
      addresses_octets.each do |octets|
        address = octets.join '.'
        yield address
      end
    end
  
  end

end


