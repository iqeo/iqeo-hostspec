
module Iqeo
  module Hostspec

    class Runner

      def self.run args, out: $stdout, err: $stderr

        if args.empty?
          err.puts "Error: No specs given"
          return 1
        end

        if args.include?('-h') || args.include?('--help')
          print_help err
          return 0
        end

        if args.include?('-v') || args.include?('--version')
          print_version err
          return 0
        end

        cmd_sw_index = args.index('-c') || args.index('--cmd')
        if cmd_sw_index
          specs = args.take(cmd_sw_index)            # specs are before switch
          cmd   = args.drop(cmd_sw_index+1).join ' ' # command components are after switch, join into string to pass to subshell
          if cmd.empty?
            err.puts "Error: No command given"
            return 2
          end
        else 
          specs = args
          cmd = nil
        end

        results = []
        specs.each do |spec|
          spec = spec.strip
          begin
            host_spec = Hostspec.new spec
          rescue Exception => e
            err.puts "Error: #{e.message}"
            return 3
          end
          if cmd.nil?
            host_spec.each { |address| out.puts address }
          else
            env = {
              'HOSTSPEC_MASK'    => host_spec.mask,
              'HOSTSPEC_MASKLEN' => host_spec.mask_length.to_s,
              'HOSTSPEC_COUNT'   => host_spec.size.to_s
            }
            host_spec.each_with_index do |address,index|
              env['HOSTSPEC_IP']    = address
              env['HOSTSPEC_INDEX'] = (index+1).to_s
              # this uses posix 'sh', to use bash user's cmd should be 'bash -c "echo \$HOSTSPEC_IP"' and deal with the weird nested quoting
              results << system( env, cmd )
            end
          end
        end
        ( results.empty? || results.all? ) ? 0 : 4
      end

      def self.print_help io
        io.puts "Usage: hostspec [ options ] specs... [ [ -c / --cmd ] command ]"
        io.puts
        io.puts "Prints all IP addresses for IP host specifications (see Specs:)."
        io.puts "If specified, a command is executed for each IP address, with related values in environment variables (see Command:)."
        io.puts
        io.puts "Specs:"
        io.puts "  Nmap-style IP host specifications, multiple specs separated by spaces."
        io.puts "  Single host       : x.x.x.x or hostname"
        io.puts "  Multiple hosts:"
        io.puts "  - by mask length  : x.x.x.x/m or hostname/m"
        io.puts "  - by octet values : x.x.x.a,b,c"
        io.puts "  - by octet ranges : x.x.x.d-e"
        io.puts "  Octet values and ranges may be combined or applied to any/multiple octets."
        io.puts "  Examples:"
        io.puts "    hostname         : localhost      => 127.0.0.1"
        io.puts "    hostname w/mask  : localhost/24   => 127.0.0.0  127.0.0.1 ... 127.0.0.254  127.0.0.255"
        io.puts "    address          : 1.0.0.1        => 1.0.0.1"
        io.puts "    address w/mask   : 2.0.0.1/24     => 2.0.0.0  2.0.0.1  ...  2.0.0.254  2.0.0.255"
        io.puts "    address w/values : 3.0.0.10,20,30 => 3.0.0.10 3.0.0.20 3.0.0.30"
        io.puts "    address w/ranges : 4.0.0.40-50    => 4.0.0.40 4.0.0.41 ...  4.0.0.49 4.0.0.50"
        io.puts "    address w/combo  : 5.0.0.2,4-6,8  => 5.0.0.2  5.0.0.4  5.0.0.5  5.0.0.6  5.0.0.8"
        io.puts "    multiple octets  : 6.1-2,3.4-5.6  => 6.1.4.6  6.1.5.6  6.2.4.6  6.2.5.6  6.3.4.6  6.3.5.6"
        io.puts
        io.puts "Command:"
        io.puts "  A command to execute for each IP address may be specified following the command switch ( -c / --cmd )."
        io.puts "  The command is executed in a separate shell for each IP address."
        io.puts "  Environment variables are provided with values for each IP address command execution."
        io.puts "  Quote these variables in the command to prevent substitution by the current shell."
        io.puts "    $HOSTSPEC_IP      : IP address"
        io.puts "    $HOSTSPEC_MASK    : Mask (255.255.255.255 if a mask length was not specified)"
        io.puts "    $HOSTSPEC_MASKLEN : Mask length (32 if a mask length was not specified)"
        io.puts "    $HOSTSPEC_COUNT   : Count of IP addresses"
        io.puts "    $HOSTSPEC_INDEX   : Index of IP address (from 1 to Count)"
        io.puts "  Examples:"
        io.puts "    Print IP addresses and mask length with index and count:"
        io.puts "      hostspec 1.1.1.0/30 --cmd echo '$HOSTSPEC_INDEX' of '$HOSTSPECT_COUNT' : '$HOSTSPEC_IP/$HOSTSPEC_MASKLEN'"
        io.puts "      ..."
        io.puts "      1 of 4 : 1.1.1.0/255.255.255.252"
        io.puts "      2 of 4 : 1.1.1.1/255.255.255.252"
        io.puts "      3 of 4 : 1.1.1.2/255.255.255.252"
        io.puts "      4 of 4 : 1.1.1.3/255.255.255.252"
        io.puts "    Collect routing tables of all hosts on a network via ssh:"
        io.puts "      hostspec 1.1.1.1-254 --cmd 'ssh me@$HOSTSPEC_IP route -n'"
        io.puts "    Collect default web pages from all servers on a network via curl:"
        io.puts "      hostspec 1.1.1.1-254 --cmd curl -o '$HOSTSPEC_IP.html' 'http://$HOSTSPEC_IP'"
        io.puts "    Collect IP configuration info from multiple windows systems (run from a windows system):"
        io.puts "      hostspec 1.1.1.1-254 --cmd psexec '\\\\%HOSTSPEC_IP%' ipconfig /all"
        io.puts "    Collect IP configuration info from multiple windows systems (run from a linux system with kerberos):"
        io.puts "      hostspec 1.1.1.1-254 --cmd winexe --kerberos yes //$(dig -x '$HOSTSPEC_IP' +short) ipconfig /all"
        io.puts "    ...or any task that you would have to execute individually on multiple systems."
        io.puts
        io.puts "Options:"
        io.puts "  -h / --help     : Display this helpful information"
        io.puts "  -v / --version  : Display program version"
        io.puts
      end

      def self.print_version io
        io.puts "hostspec version #{Iqeo::Hostspec::VERSION}"
      end

    end

  end
end

