
# Internal: The logic of the solution-lint bin script, contained in a class for
# ease of testing.
class SolutionLint::Bin
  # Public: Initialise a new SolutionLint::Bin.
  #
  # args - An Array of command line argument Strings to be passed to the option
  #        parser.
  #
  # Examples
  #
  #   SolutionLint::Bin.new(ARGV).run
  def initialize(args)
    @args = args
  end

  # Public: Run solution-lint as a command line tool.
  #
  # Returns an Integer exit code to be passed back to the shell.
  def run

    begin
      path = @args[0]
      if File.directory?(path)
        path = Dir.glob("#{path}/**/*.yaml")
      else
        path = @args
      end

      return_val = 0
      path.each do |f|
        l = SolutionLint.new
        l.file = f
        l.run
        l.print_problems
        if l.errors? or l.warnings?
          return_val = 1
        end
      end
      return return_val

    rescue SolutionLint::NoCodeError
      puts "solution-lint: no file specified or specified file does not exist"
      puts "solution-lint: try 'solution-lint --help' for more information"
      return 1
    end
  end
end