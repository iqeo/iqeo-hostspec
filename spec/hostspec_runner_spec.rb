load './bin/hostspec'

require 'stringio'

describe Runner do

  it 'requires 2 arguments (and 2 optional streams)' do
    expect { Runner.run                }.to raise_error
    expect { Runner.run '1.1.1.1'      }.to raise_error
    expect { Runner.run '1.1.1.1', nil, StringIO.new, StringIO.new }.to_not raise_error
    expect { Runner.run '1.1.1.1', '' , StringIO.new, StringIO.new }.to_not raise_error
  end

  it 'accepts a host spec for the first argument' do
    Runner.run( '10.20.30.40',                nil, StringIO.new, StringIO.new ).should eq 0
    Runner.run( '10.20.30.40/24',             nil, StringIO.new, StringIO.new ).should eq 0
    Runner.run( '10,11.20-29.30,31-38,39.40', nil, StringIO.new, StringIO.new ).should eq 0
    Runner.run( 'localhost',                  nil, StringIO.new, StringIO.new ).should eq 0
    Runner.run( 'no-such-host/xyz',           nil, StringIO.new, StringIO.new ).should_not eq 0
  end

  it 'accepts multiple host specs for the first argument'

  it 'lists host spec IP addresses if there is no second argument' do
    [ nil, '', '  ' ].each do |cmd| 
      output = StringIO.new
      Runner.run( '1.1.1.1-5', cmd, output )
      output.string.should eq "1.1.1.1\n1.1.1.2\n1.1.1.3\n1.1.1.4\n1.1.1.5\n"
    end
  end

  context 'prints usage info' do

    it 'for -h or --help switch'

    it 'for no arguments'

  end

  context 'executes the second argument as a shell command' do

    it 'with hostspec-related values in environment variables $HOSTSPEC_IP, $HOSTSPEC_MASK, $HOSTSPEC_MASKLEN, $HOSTSPEC_COUNT, $HOSTSPEC_INDEX' # do
      # output = StringIO.new
      # Runner.run( '1.1.1.1-5', 'echo $HOSTSPEC_IP, $HOSTSPEC_MASK, $HOSTSPEC_MASKLEN, $HOSTSPEC_COUNT, $HOSTSPEC_INDEX', output )
      # output.string.should eq "1.1.1.1 255.255.255.255 32 6 0\n....."
    # end

  end

end
