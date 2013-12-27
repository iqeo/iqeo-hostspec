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

    attr_reader :mask, :mask_length, :mask_int, :ip, :ip_int, :hostname

    def initialize specstr
      raise HostspecException, 'spec cannot be empty' if specstr.empty?
      host_str, mask_str = split_on_slash specstr
      raise HostspecException, 'host cannot be empty' if host_str.empty?
      parse_mask mask_str
      begin
        parse_ip   host_str
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
    
    def parse_ip str
      octet_strs = str.split '.'
      raise HostspecException, 'bad ip, expected 4 octets' unless octet_strs.size == 4    
      octets = octet_strs.collect do |octet_str|
        match = octet_str.match /^(0*1?\d?\d|2[0-4][0-9]|25[0-5])$/
        raise HostspecException, 'bad ip, invalid octet' unless match
        match.to_s.to_i
      end
      @ip = octets.join '.'
      @ip_int = octets.reverse.collect.each_with_index { |octet,i| octet*(2**(i*8)) }.inject(:+)
    end
    
    def parse_hostname str
        @hostname = str
        parse_ip Resolv.getaddress(str)
    end

  end
end

