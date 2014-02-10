load './bin/hostspec'

require 'stringio'

describe Runner do

  it 'expects an array of arguments' do
    expect { Runner.run           }.to raise_error
    expect { Runner.run nil       }.to raise_error
    expect { Runner.run '1.1.1.1' }.to raise_error
    expect { Runner.run [], out: StringIO.new, err: StringIO.new }.to_not raise_error
  end

  it 'accepts single host spec for argument with no switches' do
    Runner.run( ['10.20.30.40'],                out: StringIO.new, err: StringIO.new ).should eq 0
    Runner.run( ['10.20.30.40/24'],             out: StringIO.new, err: StringIO.new ).should eq 0
    Runner.run( ['10,11.20-29.30,31-38,39.40'], out: StringIO.new, err: StringIO.new ).should eq 0
    Runner.run( ['localhost'],                  out: StringIO.new, err: StringIO.new ).should eq 0
  end

  it 'accepts multiple host specs for arguments with no switches' do
    Runner.run( ['10.20.30.40/24','11.22.33.44'],                out: StringIO.new, err: StringIO.new ).should eq 0
    Runner.run( ['10,11.20-29.30,31-38,39.40','11.22.33.44/28'], out: StringIO.new, err: StringIO.new ).should eq 0
    Runner.run( ['localhost','1.2.3.4/26','11.22.33.44-55'],     out: StringIO.new, err: StringIO.new ).should eq 0
  end

  it 'expects valid single host spec or prints error' do
    error = StringIO.new
    Runner.run( ['no-such-host/xyz'], out: StringIO.new, err: error ).should eq 3
    error.string.should include 'Error'
  end

  it 'expects valid multiple host specs or prints error' do
    error = StringIO.new
    Runner.run( ['no-such-host/xyz','5.5.5.5'], out: StringIO.new, err: error ).should eq 3
    error.string.should include 'Error'
  end

  it 'lists single host spec IP addresses to stdout for no command (-c/--cmd) switch' do
    output = StringIO.new
    Runner.run( ['1.1.1.1-5'], out: output )
    output.string.should eq "1.1.1.1\n1.1.1.2\n1.1.1.3\n1.1.1.4\n1.1.1.5\n"
  end

  it 'lists multiple host spec IP addresses to stdout for no command (-c/--cmd) switch' do
    output = StringIO.new
    Runner.run( ['1.1.1.1-5','2.2.2.4,6,8'], out: output )
    output.string.should eq "1.1.1.1\n1.1.1.2\n1.1.1.3\n1.1.1.4\n1.1.1.5\n2.2.2.4\n2.2.2.6\n2.2.2.8\n"
  end

  it 'accepts host specs for arguments before command (-c/--cmd) switch' do
    Runner.run( ['1.1.1.1','2.2.2.2','-c'   ,'#'], out: StringIO.new, err: StringIO.new ).should eq 0
    Runner.run( ['1.1.1.1','2.2.2.2','--cmd','#'], out: StringIO.new, err: StringIO.new ).should eq 0
  end

  it 'expects a command argument after command (-c/--cmd) switch or prints error' do
    [['-c'],['-c',nil],['-c',''],['--cmd'],['--cmd',nil],['--cmd','']].each do |args|
      error = StringIO.new
      Runner.run( ['1.1.1.1','2.2.2.2',*args], out: StringIO.new, err: error ).should eq 2
      error.string.should include 'Error'
    end
  end

  it 'prints an error message to stderr for no arguments' do
    error = StringIO.new
    Runner.run( [], out: StringIO.new, err: error ).should eq 1
    error.string.should include 'Error'
  end

  it 'prints a helpful message to stderr for help (-h/--help) switch' do
    [['-h'],['1.2.3.4','-h'],['-h','1.2.3.4'],['1.2.3.4','-h','5.6.7.8'],['--help'],['1.2.3.4','--help'],['--help','1.2.3.4'],['1.2.3.4','--help','5.6.7.8']].each do |args|
      error = StringIO.new
      Runner.run( args, out: StringIO.new, err: error ).should eq 0
      error.string.should include 'hostspec'
    end
  end

  it 'prints version info to stderr for version (-v/--version) switch' do
    [['-v'],['1.2.3.4','-v'],['-v','1.2.3.4'],['1.2.3.4','-v','5.6.7.8'],['--version'],['1.2.3.4','--version'],['--version','1.2.3.4'],['1.2.3.4','--version','5.6.7.8']].each do |args|
      error = StringIO.new
      Runner.run( args, out: StringIO.new, err: error ).should eq 0
      error.string.should include 'hostspec'
      error.string.should include Iqeo::Hostspec::VERSION 
    end
  end

  it 'executes the argument after the command (-c/--cmd) switch as a shell command' do
    File.delete 'test.txt' if File.exists? 'test.txt'
    Runner.run( ['1.1.1.1-3','2.2.2.1-3','-c','echo X >> test.txt'] ).should eq 0
    File.read('test.txt').should eq "X\n" * 6
    File.delete 'test.txt' if File.exists? 'test.txt'
  end

  it 'provides hostspec values to command via environment variables $HOSTSPEC_IP, $HOSTSPEC_MASK, $HOSTSPEC_MASKLEN, $HOSTSPEC_COUNT, $HOSTSPEC_INDEX' do
    File.delete 'test.txt' if File.exists? 'test.txt'
    Runner.run( ['1.1.1.1-3','2.2.2.1-3','-c','echo $HOSTSPEC_IP $HOSTSPEC_MASK $HOSTSPEC_MASKLEN $HOSTSPEC_COUNT $HOSTSPEC_INDEX >> test.txt'] )
    File.read('test.txt').should eq "1.1.1.1 255.255.255.255 32 3 1\n1.1.1.2 255.255.255.255 32 3 2\n1.1.1.3 255.255.255.255 32 3 3\n2.2.2.1 255.255.255.255 32 3 1\n2.2.2.2 255.255.255.255 32 3 2\n2.2.2.3 255.255.255.255 32 3 3\n" 
    File.delete 'test.txt' if File.exists? 'test.txt'
  end

  it 'returns 0 on successful execution of commands' do
    Runner.run( ['1.1.1.1-10','-c','echo'] ).should eq 0
  end

  it 'returns 4 on failure of execution of any command' do
    Runner.run( ['1.1.1.1-10','-c',"no-way-this-is-a-valid-command-#{rand(99999999)}"] ).should eq 4
  end
  
end
