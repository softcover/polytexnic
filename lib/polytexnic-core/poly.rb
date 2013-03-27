require 'polytexnic-core/command'

class Poly < Command

  def parser
    OptionParser.new do |opts|
      opts.banner = "Usage: poly <filename> [options]"
      opts.on("-f", "--foo", "foo bar") do |opt|
        self.options.foo = opt
      end
      opts.on_tail("-h", "--help", "this usage guide") do
        puts opts.to_s; exit 0
      end
    end
  end

  def cmd
    puts ARGV.inspect
    'foo'
  end
end