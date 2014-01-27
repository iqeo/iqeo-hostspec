require 'iqeo/hostspec'
require 'awesome_print'

describe Iqeo::Hostspec do

  context '.new' do

    it 'accepts a single argument only' do
      expect { Iqeo::Hostspec.new                     }.to     raise_error
      expect { Iqeo::Hostspec.new "1.1.1.1"           }.to_not raise_error
      expect { Iqeo::Hostspec.new "1.1.1.1","2.2.2.2" }.to     raise_error
    end

    it 'does not require a mask length' do
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

    context 'an IP address' do

      it 'may specify a single host without a mask length' do
        @octets.each_cons(4) do |octets|
          address = octets.join('.')
          hs = Iqeo::Hostspec.new address
          hs.address_spec.collect(&:first).should eq octets
        end 
      end 

      it 'may specify address range with a classful mask length' do
        slash_specs = {
          '1.1.1.1/32' => [[1],[1],[1],[1]],
          '1.1.1.1/24' => [[1],[1],[1],[0..255]],
          '1.1.1.1/16' => [[1],[1],[0..255],[0..255]],
          '1.1.1.1/8'  => [[1],[0..255],[0..255],[0..255]],
          '1.1.1.1/0'  => [[0..255],[0..255],[0..255],[0..255]]
        }
        slash_specs.each do |spec_str,spec_data|
          hs = Iqeo::Hostspec.new spec_str
          hs.address_spec.should eq spec_data
        end
      end

      it 'may specify address range with any mask length' do
        slash_specs = {
          '0.0.0.0/32' => [[0],[0],[0],[0]     ],
          '0.0.0.0/31' => [[0],[0],[0],[0..1]  ],
          '0.0.0.0/30' => [[0],[0],[0],[0..3]  ],
          '0.0.0.0/29' => [[0],[0],[0],[0..7]  ],
          '0.0.0.0/28' => [[0],[0],[0],[0..15] ],
          '0.0.0.0/27' => [[0],[0],[0],[0..31] ],
          '0.0.0.0/26' => [[0],[0],[0],[0..63] ],
          '0.0.0.0/25' => [[0],[0],[0],[0..127]],
          '0.0.0.0/24' => [[0],[0],[0],[0..255]],
          '0.0.0.0/23' => [[0],[0],[0..1]  ,[0..255]],
          '0.0.0.0/22' => [[0],[0],[0..3]  ,[0..255]],
          '0.0.0.0/21' => [[0],[0],[0..7]  ,[0..255]],
          '0.0.0.0/20' => [[0],[0],[0..15] ,[0..255]],
          '0.0.0.0/19' => [[0],[0],[0..31] ,[0..255]],
          '0.0.0.0/18' => [[0],[0],[0..63] ,[0..255]],
          '0.0.0.0/17' => [[0],[0],[0..127],[0..255]],
          '0.0.0.0/16' => [[0],[0],[0..255],[0..255]],
          '0.0.0.0/15' => [[0],[0..1]  ,[0..255],[0..255]],
          '0.0.0.0/14' => [[0],[0..3]  ,[0..255],[0..255]],
          '0.0.0.0/13' => [[0],[0..7]  ,[0..255],[0..255]],
          '0.0.0.0/12' => [[0],[0..15] ,[0..255],[0..255]],
          '0.0.0.0/11' => [[0],[0..31] ,[0..255],[0..255]],
          '0.0.0.0/10' => [[0],[0..63] ,[0..255],[0..255]],
          '0.0.0.0/9'  => [[0],[0..127],[0..255],[0..255]],
          '0.0.0.0/8'  => [[0],[0..255],[0..255],[0..255]],
          '0.0.0.0/7'  => [[0..1]  ,[0..255],[0..255],[0..255]],
          '0.0.0.0/6'  => [[0..3]  ,[0..255],[0..255],[0..255]],
          '0.0.0.0/5'  => [[0..7]  ,[0..255],[0..255],[0..255]],
          '0.0.0.0/4'  => [[0..15] ,[0..255],[0..255],[0..255]],
          '0.0.0.0/3'  => [[0..31] ,[0..255],[0..255],[0..255]],
          '0.0.0.0/2'  => [[0..63] ,[0..255],[0..255],[0..255]],
          '0.0.0.0/1'  => [[0..127],[0..255],[0..255],[0..255]],
          '0.0.0.0/0'  => [[0..255],[0..255],[0..255],[0..255]],
          '127.127.127.127/32' => [[127],[127],[127],[127]     ],
          '127.127.127.127/31' => [[127],[127],[127],[126..127]],
          '127.127.127.127/30' => [[127],[127],[127],[124..127]],
          '127.127.127.127/29' => [[127],[127],[127],[120..127]],
          '127.127.127.127/28' => [[127],[127],[127],[112..127]],
          '127.127.127.127/27' => [[127],[127],[127],[96..127] ],
          '127.127.127.127/26' => [[127],[127],[127],[64..127] ],
          '127.127.127.127/25' => [[127],[127],[127],[0..127]  ],
          '127.127.127.127/24' => [[127],[127],[127],[0..255]  ],
          '127.127.127.127/23' => [[127],[127],[126..127],[0..255]],
          '127.127.127.127/22' => [[127],[127],[124..127],[0..255]],
          '127.127.127.127/21' => [[127],[127],[120..127],[0..255]],
          '127.127.127.127/20' => [[127],[127],[112..127],[0..255]],
          '127.127.127.127/19' => [[127],[127],[96..127] ,[0..255]],
          '127.127.127.127/18' => [[127],[127],[64..127] ,[0..255]],
          '127.127.127.127/17' => [[127],[127],[0..127]  ,[0..255]],
          '127.127.127.127/16' => [[127],[127],[0..255]  ,[0..255]],
          '127.127.127.127/15' => [[127],[126..127],[0..255],[0..255]],
          '127.127.127.127/14' => [[127],[124..127],[0..255],[0..255]],
          '127.127.127.127/13' => [[127],[120..127],[0..255],[0..255]],
          '127.127.127.127/12' => [[127],[112..127],[0..255],[0..255]],
          '127.127.127.127/11' => [[127],[96..127] ,[0..255],[0..255]],
          '127.127.127.127/10' => [[127],[64..127] ,[0..255],[0..255]],
          '127.127.127.127/9'  => [[127],[0..127]  ,[0..255],[0..255]],
          '127.127.127.127/8'  => [[127],[0..255]  ,[0..255],[0..255]],
          '127.127.127.127/7'  => [[126..127],[0..255],[0..255],[0..255]],
          '127.127.127.127/6'  => [[124..127],[0..255],[0..255],[0..255]],
          '127.127.127.127/5'  => [[120..127],[0..255],[0..255],[0..255]],
          '127.127.127.127/4'  => [[112..127],[0..255],[0..255],[0..255]],
          '127.127.127.127/3'  => [[96..127] ,[0..255],[0..255],[0..255]],
          '127.127.127.127/2'  => [[64..127] ,[0..255],[0..255],[0..255]],
          '127.127.127.127/1'  => [[0..127]  ,[0..255],[0..255],[0..255]],
          '127.127.127.127/0'  => [[0..255]  ,[0..255],[0..255],[0..255]],
          '128.128.128.128/32' => [[128],[128],[128],[128]     ],
          '128.128.128.128/31' => [[128],[128],[128],[128..129]],
          '128.128.128.128/30' => [[128],[128],[128],[128..131]],
          '128.128.128.128/29' => [[128],[128],[128],[128..135]],
          '128.128.128.128/28' => [[128],[128],[128],[128..143]],
          '128.128.128.128/27' => [[128],[128],[128],[128..159]],
          '128.128.128.128/26' => [[128],[128],[128],[128..191]],
          '128.128.128.128/25' => [[128],[128],[128],[128..255]],
          '128.128.128.128/24' => [[128],[128],[128],[0..255]  ],
          '128.128.128.128/23' => [[128],[128],[128..129],[0..255]],
          '128.128.128.128/22' => [[128],[128],[128..131],[0..255]],
          '128.128.128.128/21' => [[128],[128],[128..135],[0..255]],
          '128.128.128.128/20' => [[128],[128],[128..143],[0..255]],
          '128.128.128.128/19' => [[128],[128],[128..159],[0..255]],
          '128.128.128.128/18' => [[128],[128],[128..191],[0..255]],
          '128.128.128.128/17' => [[128],[128],[128..255],[0..255]],
          '128.128.128.128/16' => [[128],[128],[0..255]  ,[0..255]],
          '128.128.128.128/15' => [[128],[128..129],[0..255],[0..255]],
          '128.128.128.128/14' => [[128],[128..131],[0..255],[0..255]],
          '128.128.128.128/13' => [[128],[128..135],[0..255],[0..255]],
          '128.128.128.128/12' => [[128],[128..143],[0..255],[0..255]],
          '128.128.128.128/11' => [[128],[128..159],[0..255],[0..255]],
          '128.128.128.128/10' => [[128],[128..191],[0..255],[0..255]],
          '128.128.128.128/9'  => [[128],[128..255],[0..255],[0..255]],
          '128.128.128.128/8'  => [[128],[0..255]  ,[0..255],[0..255]],
          '128.128.128.128/7'  => [[128..129],[0..255],[0..255],[0..255]],
          '128.128.128.128/6'  => [[128..131],[0..255],[0..255],[0..255]],
          '128.128.128.128/5'  => [[128..135],[0..255],[0..255],[0..255]],
          '128.128.128.128/4'  => [[128..143],[0..255],[0..255],[0..255]],
          '128.128.128.128/3'  => [[128..159],[0..255],[0..255],[0..255]],
          '128.128.128.128/2'  => [[128..191],[0..255],[0..255],[0..255]],
          '128.128.128.128/1'  => [[128..255],[0..255],[0..255],[0..255]],
          '128.128.128.128/0'  => [[0..255]  ,[0..255],[0..255],[0..255]],
          '255.255.255.255/32' => [[255],[255],[255],[255]     ],
          '255.255.255.255/31' => [[255],[255],[255],[254..255]],
          '255.255.255.255/30' => [[255],[255],[255],[252..255]],
          '255.255.255.255/29' => [[255],[255],[255],[248..255]],
          '255.255.255.255/28' => [[255],[255],[255],[240..255]],
          '255.255.255.255/27' => [[255],[255],[255],[224..255]],
          '255.255.255.255/26' => [[255],[255],[255],[192..255]],
          '255.255.255.255/25' => [[255],[255],[255],[128..255]],
          '255.255.255.255/24' => [[255],[255],[255],[0..255]  ], 
          '255.255.255.255/23' => [[255],[255],[254..255],[0..255]],
          '255.255.255.255/22' => [[255],[255],[252..255],[0..255]],
          '255.255.255.255/21' => [[255],[255],[248..255],[0..255]],
          '255.255.255.255/20' => [[255],[255],[240..255],[0..255]],
          '255.255.255.255/19' => [[255],[255],[224..255],[0..255]],
          '255.255.255.255/18' => [[255],[255],[192..255],[0..255]],
          '255.255.255.255/17' => [[255],[255],[128..255],[0..255]],
          '255.255.255.255/16' => [[255],[255],[0..255]  ,[0..255]],
          '255.255.255.255/15' => [[255],[254..255],[0..255],[0..255]],
          '255.255.255.255/14' => [[255],[252..255],[0..255],[0..255]],
          '255.255.255.255/13' => [[255],[248..255],[0..255],[0..255]],
          '255.255.255.255/12' => [[255],[240..255],[0..255],[0..255]],
          '255.255.255.255/11' => [[255],[224..255],[0..255],[0..255]],
          '255.255.255.255/10' => [[255],[192..255],[0..255],[0..255]],
          '255.255.255.255/9'  => [[255],[128..255],[0..255],[0..255]],
          '255.255.255.255/8'  => [[255],[0..255]  ,[0..255],[0..255]],
          '255.255.255.255/7'  => [[254..255],[0..255],[0..255],[0..255]],
          '255.255.255.255/6'  => [[252..255],[0..255],[0..255],[0..255]],
          '255.255.255.255/5'  => [[248..255],[0..255],[0..255],[0..255]],
          '255.255.255.255/4'  => [[240..255],[0..255],[0..255],[0..255]],
          '255.255.255.255/3'  => [[224..255],[0..255],[0..255],[0..255]],
          '255.255.255.255/2'  => [[192..255],[0..255],[0..255],[0..255]],
          '255.255.255.255/1'  => [[128..255],[0..255],[0..255],[0..255]],
          '255.255.255.255/0'  => [[0..255]  ,[0..255],[0..255],[0..255]],
        }
        slash_specs.each do |spec_str,spec_data|
          hs = Iqeo::Hostspec.new spec_str
          hs.address_spec.should eq spec_data
        end
      end

    end

    context 'a hostname' do

      it 'is assumed when not a simple IP spec' do
        Iqeo::Hostspec.new('localhost').hostname.should eq 'localhost'
      end

      it 'is assumed when not a complex IP spec' do
        expect { hs = Iqeo::Hostspec.new "1.2.3.100-300" }.to raise_error Resolv::ResolvError 
      end

      it 'resolves to a host IP address' do
        hs = Iqeo::Hostspec.new('localhost') 
        hs.hostname.should eq 'localhost'
        hs.address_spec.collect(&:first).should eq [127,0,0,1]
        hs.mask.should eq '255.255.255.255'
        hs.mask_length.should eq 32
      end

      it 'may specify address range with a mask length' do
        (0..32).each do |masklen|
          hs = Iqeo::Hostspec.new("localhost/#{masklen}")
          hs.mask_length.should eq masklen
        end
      end
  
    end

    context 'a complex IP address spec' do

      it 'must not specify a mask length' do
        (0..32).each do |masklen|
          expect { hs = Iqeo::Hostspec.new "10.20,22,24.30-39.40/#{masklen}" }.to raise_error
        end
      end
      
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

      it 'may not specifiy a reversed range' do
        expect { hs = Iqeo::Hostspec.new '1.1.1.20-10' }.to raise_error
      end
    
    end

  end

  context 'instance' do

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
      @specs_with_slash = {
        '10.20.30.40/28' => [
          '10.20.30.32', '10.20.30.33', '10.20.30.34', '10.20.30.35', '10.20.30.36', '10.20.30.37', '10.20.30.38', '10.20.30.39',
          '10.20.30.40', '10.20.30.41', '10.20.30.42', '10.20.30.43', '10.20.30.44', '10.20.30.45', '10.20.30.46', '10.20.30.47',
        ],
        '10.20.30.40/27' => [
          '10.20.30.32', '10.20.30.33', '10.20.30.34', '10.20.30.35', '10.20.30.36', '10.20.30.37', '10.20.30.38', '10.20.30.39',
          '10.20.30.40', '10.20.30.41', '10.20.30.42', '10.20.30.43', '10.20.30.44', '10.20.30.45', '10.20.30.46', '10.20.30.47',
          '10.20.30.48', '10.20.30.49', '10.20.30.50', '10.20.30.51', '10.20.30.52', '10.20.30.53', '10.20.30.54', '10.20.30.55',
          '10.20.30.56', '10.20.30.57', '10.20.30.58', '10.20.30.59', '10.20.30.60', '10.20.30.61', '10.20.30.62', '10.20.30.63',
        ]
      }

    end

    shared_examples "enumerates" do |method|
        
      it 'a single address for host address' do
        @octets.each_cons(4) do |octets|
          address = octets.join('.')
          hs = Iqeo::Hostspec.new address
          address_count = 0
          hs.send(method) do |address_str|
            address_str.should eq address
            address_count += 1
          end
          address_count.should eq 1
        end 
      end

      it 'multiple addresses for a spec with multiple octet values (commas)' do
        hs = Iqeo::Hostspec.new @multi_spec_with_commas
        address_count = 0
        hs.send(method) do |address_str|
          address_str.should eq @multi_expected_addresses[address_count]
          address_count +=1
        end
        address_count.should eq @multi_expected_addresses.size
      end

      it 'multiple addresses for a spec with octet ranges (dashes)' do
        hs = Iqeo::Hostspec.new @multi_spec_with_dashes
        address_count = 0
        hs.send(method) do |address_str|
          address_str.should eq @multi_expected_addresses[address_count]
          address_count +=1
        end
        address_count.should eq @multi_expected_addresses.size
      end

      it 'masked addresses for specs with a mask length' do
        @specs_with_slash.each do |address_spec,expected_addresses|
          hs = Iqeo::Hostspec.new address_spec
          address_count = 0
          hs.send(method) do |address_str|
            address_str.should eq expected_addresses[address_count]
            address_count += 1
          end
          address_count.should eq expected_addresses.size
        end
      end

    end

    context '.each_address enumerates' do
      include_examples 'enumerates', :each_address
    end

    context '.each enumerates' do
      include_examples 'enumerates', :each
    end

    context 'enumerable' do
      
      it '.each returns an Enumerator' do
        hs = Iqeo::Hostspec.new '10.20.30.40/24'
        hs.each.class.should eq Enumerator
      end

      it 'responds to Enumerable methods' do
        hs = Iqeo::Hostspec.new '10.20.30.40/24'
        hs.all? { |i| i.start_with? '10' }.should be_true
        hs.any? { |i| i.end_with? '255'  }.should be_true
      end

      it 'can calculate size for simple specs' do
        (0..32).each do |masklen|
          hs = Iqeo::Hostspec.new "10.20.30.40/#{masklen}"
          hs.size.should eq 2**(32-masklen)
        end
      end

      it 'can calculate size for complex specs' do
        hs = Iqeo::Hostspec.new @multi_spec_with_commas
        hs.size.should eq @multi_expected_addresses.size
        hs = Iqeo::Hostspec.new @multi_spec_with_dashes
        hs.size.should eq @multi_expected_addresses.size
      end

      it 'Enumerator can make use of size' do
        hs = Iqeo::Hostspec.new '1.1.1.1-10'
        hs.size.should eq 10
        enumerator = hs.each
        enumerator.size.should eq 10
      end

      it 'has first (from enumerable)' do
        hs = Iqeo::Hostspec.new '1.1.2-10.20-100'
        hs.first.should eq '1.1.2.20'
      end
      
      it 'has last' do
        hs = Iqeo::Hostspec.new '1.1.2-10.20-100'
        hs.last.should eq '1.1.10.100'
      end

      it 'has min equals first' do
        hs = Iqeo::Hostspec.new '1.1.2-10.20-100'
        hs.min.should eq '1.1.2.20'
      end

      it 'has max equals last' do
        hs = Iqeo::Hostspec.new '1.1.2-10.20-100'
        hs.max.should eq '1.1.10.100'
      end

      it 'has minmax' do
        hs = Iqeo::Hostspec.new '1.1.2-10.20-100'
        hs.minmax.should eq ['1.1.2.20','1.1.10.100']
      end

    end

  end

end

