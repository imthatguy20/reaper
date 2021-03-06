# Taken from the Metasploit Framework Tools folder
# https://github.com/rapid7/metasploit-framework/blob/master/tools/exploit/pattern_create.rb

require 'optparse'

module PatternCreate
  class OptsConsole
    def self.parse(args)
      options = {}
      parser = OptionParser.new do |opt|
        opt.banner = "Usage: reaper pate [options]\nExample: reaper pate -l 50 -s ABC,def,123\nAd1Ad2Ad3Ae1Ae2Ae3Af1Af2Af3Bd1Bd2Bd3Be1Be2Be3Bf1Bf"
        opt.separator ''
        opt.separator 'Options:'
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
      elsif options[:length].nil? && options[:sets]
        raise OptionParser::MissingArgument, '-l <length> is required'
      end

      options[:sets] = nil unless options[:sets]

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

      puts Rex::Text.pattern_create(@opts[:length], @opts[:sets])
    end
  end
end

driver = PatternCreate::Driver.new
begin
	driver.run
rescue ::StandardError => e
  $stderr.puts "[x] #{e.class}: #{e.message}"
end
