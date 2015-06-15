require 'set'
require 'solution-lint/version'
require 'solution-lint/checks'
require 'solution-lint/configuration'
require 'solution-lint/bin'
require 'yaml'

class SolutionLint::NoCodeError < StandardError; end
class SolutionLint::NoFix < StandardError; end

# Public: The public interface to solution-lint.
class SolutionLint
  # Public: Gets/Sets the YAML dataset to be checked.
  attr_accessor :code

  # Public: Returns an Array of Hashes describing the problems found in the
  # manifest.
  #
  # Each Hash will contain *at least*:
  #   :check   - The Symbol name of the check that generated the problem.
  #   :kind    - The Symbol kind of the problem (:error, :warning, or
  #              :fixed).
  #   :line    - The Integer line number of the location of the problem in
  #              the manifest.
  #   :column  - The Integer column number of the location of the problem in
  #              the manifest.
  #   :message - The String message describing the problem that was found.
  attr_reader :problems

  # Public: Gets/Sets the String path to the manifest to be checked.
  attr_accessor :path

  # Public: Returns a Hash of linter statistics
  #
  #   :error   - An Integer count of errors found in the manifest.
  #   :warning - An Integer count of warnings found in the manifest.
  #   :fixed   - An Integer count of problems found in the manifest that were
  #              automatically fixed.
  attr_reader :statistics

  # Public: Initialise a new SolutionLint object.
  def initialize
    @code = nil
    @statistics = {:error => 0, :warning => 0, :fixed => 0, :ignored => 0}
    @manifest = ''
  end

  # Public: Access SolutionLint's configuration from outside the class.
  #
  # Returns a SolutionLint::Configuration object.
  def self.configuration
    @configuration ||= SolutionLint::Configuration.new
  end

  # Public: Access SolutionLint's configuration from inside the class.
  #
  # Returns a SolutionLint::Configuration object.
  def configuration
    self.class.configuration
  end


  # Public: Set the path of the manifest file to be tested and read the
  # contents of the file.
  #
  # Returns nothing.
  def file=(path)
    if File.exist? path
      @path = path
      @file = File.read(path)
      puts "loading file #{@file}"
      @code = YAML.load(@file)
    end
  end

  # Internal: Retrieve the format string to be used when writing problems to
  # STDOUT.  If the user has not specified a custom log format, build one for
  # them.
  #
  # Returns a format String to be used with String#%.
  def log_format
    @log_format = '%{KIND}: %{message} on line %{line}'
  end

  # Internal: Format a problem message and print it to STDOUT.
  #
  # message - A Hash containing all the information about a problem.
  #
  # Returns nothing.
  def format_message(message)
    format = @log_format
    puts format % message
    if message[:kind] == :ignored && !message[:reason].nil?
      puts "  #{message[:reason]}"
    end
  end

  # Internal: Print out the line of the manifest on which the problem was found
  # as well as a marker pointing to the location on the line.
  #
  # message - A Hash containing all the information about a problem.
  #
  # Returns nothing.
  def print_context(message)
    return if message[:check] == 'documentation'
    return if message[:kind] == :fixed
    line = @file.split("\n")[message[:line] - 1]
    offset = line.index(/\S/) || 1
    puts "\n  #{line.strip}"
    printf "%#{message[:column] + 2 - offset}s\n\n", '^'
  end

  # Internal: Print the reported problems with a manifest to stdout.
  #
  # problems - An Array of problem Hashes as returned by
  #            SolutionLint::Checks#run.
  #
  # Returns nothing.
  def report(problems)
    problems.each do |message|

      message[:KIND] = message[:kind].to_s.upcase
      message[:linenumber] = message[:line]

      format_message message
      print_context(message)
    end
  end

  # Public: Determine if SolutionLint found any errors in the manifest.
  #
  # Returns true if errors were found, otherwise returns false.
  def errors?
    @statistics[:error] != 0
  end

  # Public: Determine if SolutionLint found any warnings in the manifest.
  #
  # Returns true if warnings were found, otherwise returns false.
  def warnings?
    @statistics[:warning] != 0
  end

  # Public: Run the loaded manifest code through the lint checks and print the
  # results of the checks to stdout.
  #
  # Returns nothing.
  # Raises SolutionLint::NoCodeError if no manifest code has been loaded.
  def run
    if @code.nil?
      raise SolutionLint::NoCodeError
    end

    if @code.empty?
      @problems = []
      @manifest = []
      return
    end

    puts "kicking off a new"
    linter = SolutionLint::Checks.new
    @problems = linter.run(@path, @code)
    @problems.each { |problem| @statistics[problem[:kind]] += 1 }

  end

  # Public: Print any problems that were found out to stdout.
  #
  # Returns nothing.
  def print_problems
    report @problems
  end

  # Public: Define a new check.
  #
  # name  - A unique name for the check as a Symbol.
  # block - The check logic. This must contain a `check` method and optionally
  #         a `fix` method.
  #
  # Returns nothing.
  #
  # Examples
  #
  #   SolutionLint.new_check(:foo) do
  #     def check
  #     end
  #   end
  def self.new_check(name, &block)
    class_name = name.to_s.split('_').map(&:capitalize).join
    klass = SolutionLint.const_set("Check#{class_name}", Class.new(SolutionLint::CheckPlugin))
    klass.const_set('NAME', name)
    klass.class_exec(&block)
    SolutionLint.configuration.add_check(name, klass)

  end
end

# Default configuration options
SolutionLint.configuration.defaults

require 'solution-lint/plugins'
