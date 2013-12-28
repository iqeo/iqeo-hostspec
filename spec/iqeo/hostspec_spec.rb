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

    context 'as simple IP address' do

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

    context 'as hostname' do

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

      it 'with mask resolves to network IP address' do
        [32,24,16,8].each do |masklen|
          hs = Iqeo::Hostspec.new("localhost/#{masklen}") 
          hs.address_spec.collect(&:first).should eq [127,0,0,1]
          hs.mask_length.should eq masklen
        end
      end
  
    end

    context 'as complex IP address spec' do

      it 'with dash'

      it 'with comma' do
        hs = Iqeo::Hostspec.new '1.2.3.4,5,6'
        hs.address_spec.should eq [[1],[2],[3],[4,5,6]]
      end

    end

  end

  context 'enumerates' do
  
    it 'single address for a host'

    it 'multiple address for a network'
  
  end

end

