require 'optparse'
require 'ostruct'

class Command
  attr_accessor :args, :cmd, :options

  def initialize(args = [])
    self.args = args
    self.options = OpenStruct.new
    parser.parse!
  end

  # Runs a command.
  # If the argument array contains '--debug', returns the command that would
  # have been run.
  def self.run!(command_class, args)
    debug = args.delete('--debug')
    command = command_class.new(args)
    if debug
      puts command.cmd 
      return 1
    else
      exit system('date >> tmp/poly.log')
    end
  end
end