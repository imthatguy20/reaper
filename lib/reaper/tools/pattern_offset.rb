# Taken from the Metasploit Framework Tools folder
# https://github.com/rapid7/metasploit-framework/blob/master/tools/exploit/pattern_offset.rb

require 'optparse'

module PatternOffset
  class OptsConsole
    def self.parse(args)
      options = {}
      parser = OptionParser.new do |opt|
        opt.banner = "Usage: reaper poset [options]\nExample: reaper poset -q Aa3A\n[*] Exact match at offset 9"
        opt.separator ''
        opt.separator 'Options:'

        opt.on('-q', '--query Aa0A', String, "Query to Locate") do |query|
          options[:query] = query
        end

        opt.on('-l', '--length <length>', Integer, "The length of the pattern") do |len|
          options[:length] = len
        end

        opt.on('-s', '--sets <ABC,def,123>', Array, "Custom Pattern Sets") do |sets|
          options[:sets] = sets
        end

        opt.on_tail('-h', '--help', 'Show this message') do
          $stdout.puts opt
          exit
        end
      end

      parser.parse!(args)

      if options.empty?
        raise OptionParser::MissingArgument, 'No options set, try -h for usage'
      elsif options[:query].nil?
        raise OptionParser::MissingArgument, '-q <query> is required'
      elsif options[:length].nil? && options[:sets]
        raise OptionParser::MissingArgument, '-l <length> is required'
      end

      options[:sets] = nil unless options[:sets]
      options[:length] = 8192 unless options[:length]

      options
    end
  end

  class Driver
    def initialize
      begin
        @opts = OptsConsole.parse(ARGV)
      rescue OptionParser::ParseError => e
        $stderr.puts "[x] #{e.message}"
        exit
      end
    end

    def run
      require 'rex/text'

      query = (@opts[:query])

      if query.length >= 8 && query.hex > 0
        query = query.hex
      # However, you can also specify a four-byte string
      elsif query.length == 4
        query = query.unpack("V").first
      else
        # Or even a hex query that isn't 8 bytes long
        query = query.to_i(16)
      end

      buffer = Rex::Text.pattern_create(@opts[:length], @opts[:sets])
      offset = Rex::Text.pattern_offset(buffer, query)

      # Handle cases where there is no match by looking for "close" matches
      unless offset
        found = false
        $stderr.puts "[*] No exact matches, looking for likely candidates..."

        # Look for shifts by a single byte
        0.upto(3) do |idx|
          0.upto(255) do |c|
            nvb = [query].pack("V")
            nvb[idx, 1] = [c].pack("C")
            nvi = nvb.unpack("V").first

            off = Rex::Text.pattern_offset(buffer, nvi)
            if off
              mle = query - buffer[off, 4].unpack("V").first
              mbe = query - buffer[off, 4].unpack("N").first
              puts "[+] Possible match at offset #{off} (adjusted [ little-endian: #{mle} | big-endian: #{mbe} ] ) byte offset #{idx}"
              found = true
            end
          end
        end

        exit! if found

        # Look for 16-bit offsets
        [0, 2].each do |idx|
          0.upto(65535) do |c|
            nvb = [query].pack("V")
            nvb[idx, 2] = [c].pack("v")
            nvi = nvb.unpack("V").first

            off = Rex::Text.pattern_offset(buffer, nvi)
            if off
              mle = query - buffer[off, 4].unpack("V").first
              mbe = query - buffer[off, 4].unpack("N").first
              puts "[+] Possible match at offset #{off} (adjusted [ little-endian: #{mle} | big-endian: #{mbe} ] )"
              found = true
            end
          end
        end
      end

      while offset
        puts "[*] Exact match at offset #{offset}"
        offset = Rex::Text.pattern_offset(buffer, query, offset + 1)
      end
    end
  end
end

driver = PatternOffset::Driver.new
begin
  driver.run
rescue ::StandardError => e
  $stderr.puts "[x] #{e.class}: #{e.message}"
end
