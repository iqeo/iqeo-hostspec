require 'iqeo/hostspec'
require 'awesome_print'

describe Iqeo::Hostspec do

  context '.new' do

    it 'accepts a single argument only' do
      expect { Iqeo::Hostspec.new                     }.to     raise_error
      expect { Iqeo::Hostspec.new "1.1.1.1"           }.to_not raise_error
      expect { Iqeo::Hostspec.new "1.1.1.1","2.2.2.2" }.to     raise_error
    end

    it 'does not require a mask or mask length' do
      expect { Iqeo::Hostspec.new "3.3.3.3" }.to_not raise_error
    end  

    it 'defaults to a host mask when none specified' do
      hs = Iqeo::Hostspec.new "4.4.4.4"
      hs.mask.should eq '255.255.255.255'
      hs.mask_length.should eq 32
    end

  end

  context 'mask length' do

    before(:all) do 
      @mask_integers = [ 0,
        2147483648, 3221225472, 3758096384, 4026531840,
        4160749568, 4227858432, 4261412864, 4278190080,
        4286578688, 4290772992, 4292870144, 4293918720,
        4294443008, 4294705152, 4294836224, 4294901760,
        4294934528, 4294950912, 4294959104, 4294963200,
        4294965248, 4294966272, 4294966784, 4294967040,
        4294967168, 4294967232, 4294967264, 4294967280,
        4294967288, 4294967292, 4294967294, 4294967295
      ]

      @mask_strings = [ '0.0.0.0',
        '128.0.0.0', '192.0.0.0', '224.0.0.0', '240.0.0.0',
        '248.0.0.0', '252.0.0.0', '254.0.0.0', '255.0.0.0',
        '255.128.0.0', '255.192.0.0', '255.224.0.0', '255.240.0.0',
        '255.248.0.0', '255.252.0.0', '255.254.0.0', '255.255.0.0',
        '255.255.128.0', '255.255.192.0', '255.255.224.0', '255.255.240.0',
        '255.255.248.0', '255.255.252.0', '255.255.254.0', '255.255.255.0',
        '255.255.255.128', '255.255.255.192', '255.255.255.224', '255.255.255.240',
        '255.255.255.248', '255.255.255.252', '255.255.255.254', '255.255.255.255'
      ]

    end

    it 'is specified numerically after /' do
      expect { Iqeo::Hostspec.new "5.5.5.5/24"  }.to_not raise_error
      expect { Iqeo::Hostspec.new "5.5.5.5/"    }.to     raise_error
      expect { Iqeo::Hostspec.new "5.5.5.5/xyz" }.to     raise_error
    end

    it 'is between 0 and 32' do
      (0..32).each do |masklen|
        hs = Iqeo::Hostspec.new "1.2.3.4/#{masklen}"
        hs.mask_length.should eq masklen
      end
    end

    it 'cannot be > 32' do
      [ 33, 100, 1000 ].each do |masklen|
        expect { Iqeo::Hostspec.new "1.2.3.4/#{masklen}" }.to raise_error
      end
    end

    it 'sets mask integer' do
      @mask_integers.each_with_index do |int,len|
        hs = Iqeo::Hostspec.new "1.2.3.4/#{len}"
        hs.mask_int.should eq int
      end
    end

    it 'sets mask string' do
      @mask_strings.each_with_index do |str,len|
        hs = Iqeo::Hostspec.new "1.2.3.4/#{len}"
        hs.mask.should eq str
      end
    end

  end

  context 'host' do

    before(:all) do
      @octets = (0..255).to_a
    end

    it 'cannot be empty' do
      expect { Iqeo::Hostspec.new ''    }.to raise_error
      expect { Iqeo::Hostspec.new '/32' }.to raise_error
    end

    context 'being a simple IP address' do

      it 'is accepted' do
        @octets.each_cons(4) do |octets|
          address = octets.join('.')
          hs = Iqeo::Hostspec.new address
          hs.address_spec.collect(&:first).should eq octets
        end 
      end  

#      it 'sets ip integer' do
#        @octets.each_cons(4) do |octets|
#          hs = Iqeo::Hostspec.new octets.join('.')
#          hs.ip_int.should eq (octets[0]*16777216 + octets[1]*65536 + octets[2]*256 + octets[3])
#        end
#      end
    
    end

    context 'being a hostname' do

      it 'is assumed when not an IP address' do
        Iqeo::Hostspec.new('localhost').hostname.should eq 'localhost'
      end

      it 'resolves to a host IP address' do
        hs = Iqeo::Hostspec.new('localhost') 
        hs.hostname.should eq 'localhost'
        hs.address_spec.collect(&:first).should eq [127,0,0,1]
        hs.mask.should eq '255.255.255.255'
        hs.mask_length.should eq 32
      end

      # it 'with mask resolves to network IP address' do
      #   [32,24,16,8].each do |masklen|
      #     hs = Iqeo::Hostspec.new("localhost/#{masklen}") 
      #     hs.address_spec.collect(&:first).should eq [127,0,0,1]
      #     hs.mask_length.should eq masklen
      #   end
      # end
  
    end

    context 'being an IP address spec' do

      it 'may specify octet values with commas' do
        hs = Iqeo::Hostspec.new '10,11,12.20,21,22.30,31,32.40,41,42'
        hs.address_spec.should eq [[10,11,12],[20,21,22],[30,31,32],[40,41,42]]
      end
      
      context 'may specify octet value ranges with dashes' do

        it 'in form "n-m"' do
          hs = Iqeo::Hostspec.new '10-19.20-29.30-39.40-49'
          hs.address_spec.should eq [[10..19],[20..29],[30..39],[40..49]]
        end  

        it 'in form "n-"' do
          hs = Iqeo::Hostspec.new '10-.20-.30-.40-'
          hs.address_spec.should eq [[10..255],[20..255],[30..255],[40..255]]
        end  
      
        it 'in form "-m"' do
          hs = Iqeo::Hostspec.new '-19.-29.-39.-49'
          hs.address_spec.should eq [[0..19],[0..29],[0..39],[0..49]]
        end  
        
        it 'in form "-"' do
          hs = Iqeo::Hostspec.new '-.-.-.-'
          hs.address_spec.should eq [[0..255],[0..255],[0..255],[0..255]]
        end  
      
      end

      it 'may mix octet specifications with dashes and commas' do
        hs = Iqeo::Hostspec.new '1,10,100,200.13-247.23-.-99'
        hs.address_spec.should eq [[1,10,100,200],[13..247],[23..255],[0..99]]
      end

      it 'may combine octet specification with dashes and commas' do
        hs = Iqeo::Hostspec.new '0,1,10,100-200,250,254,255.-50,99,200-.-33,44,55-66,77,88-.-'
        hs.address_spec.should eq [[0,1,10,100..200,250,254,255],[0..50,99,200..255],[0..33,44,55..66,77,88..255],[0..255]]
      end

    end

  end

  context 'enumerates' do

    before(:all) do
      @octets = (0..255).to_a
      @multi_spec_with_commas = '10,11,12.20,21,22.30,31,32.40,41,42'
      @multi_spec_with_dashes = '10-12.20-22.30-32.40-42'
      @multi_expected_addresses = [
        '10.20.30.40','10.20.30.41','10.20.30.42','10.20.31.40','10.20.31.41','10.20.31.42','10.20.32.40','10.20.32.41','10.20.32.42',
        '10.21.30.40','10.21.30.41','10.21.30.42','10.21.31.40','10.21.31.41','10.21.31.42','10.21.32.40','10.21.32.41','10.21.32.42',
        '10.22.30.40','10.22.30.41','10.22.30.42','10.22.31.40','10.22.31.41','10.22.31.42','10.22.32.40','10.22.32.41','10.22.32.42',
        '11.20.30.40','11.20.30.41','11.20.30.42','11.20.31.40','11.20.31.41','11.20.31.42','11.20.32.40','11.20.32.41','11.20.32.42',
        '11.21.30.40','11.21.30.41','11.21.30.42','11.21.31.40','11.21.31.41','11.21.31.42','11.21.32.40','11.21.32.41','11.21.32.42',
        '11.22.30.40','11.22.30.41','11.22.30.42','11.22.31.40','11.22.31.41','11.22.31.42','11.22.32.40','11.22.32.41','11.22.32.42',
        '12.20.30.40','12.20.30.41','12.20.30.42','12.20.31.40','12.20.31.41','12.20.31.42','12.20.32.40','12.20.32.41','12.20.32.42',
        '12.21.30.40','12.21.30.41','12.21.30.42','12.21.31.40','12.21.31.41','12.21.31.42','12.21.32.40','12.21.32.41','12.21.32.42',
        '12.22.30.40','12.22.30.41','12.22.30.42','12.22.31.40','12.22.31.41','12.22.31.42','12.22.32.40','12.22.32.41','12.22.32.42',
      ]
    end
  
    it 'a single address for host address' do
      @octets.each_cons(4) do |octets|
        address = octets.join('.')
        hs = Iqeo::Hostspec.new address
        address_count = 0
        hs.each_address do |address_str|
          address_str.should eq address
          address_count += 1
        end
        address_count.should eq 1
      end 
    end

    it 'multiple addresses for a spec with multiple octet values (commas)' do
      hs = Iqeo::Hostspec.new @multi_spec_with_commas
      address_count = 0
      hs.each_address do |address_str|
        address_str.should eq @multi_expected_addresses[address_count]
        address_count +=1
      end
      address_count.should eq @multi_expected_addresses.size
    end

    it 'multiple addresses for a spec with octet ranges (dashes)' do
      hs = Iqeo::Hostspec.new @multi_spec_with_dashes
      address_count = 0
      hs.each_address do |address_str|
        address_str.should eq @multi_expected_addresses[address_count]
        address_count +=1
      end
      address_count.should eq @multi_expected_addresses.size
    end

    it 'network addresses for a spec with a subnet mask'

  end

end

