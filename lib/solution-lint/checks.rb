require 'solution-lint/checkplugin'
require 'yaml'

# Internal: Various methods that orchestrate the actions of the solution-lint
# check plugins.
class SolutionLint::Checks
  # Public: Get an Array of problem Hashes.
  attr_accessor :problems

  # Public: Initialise a new SolutionLint::Checks object.
  def initialize
    @problems = []
  end

  # Internal: Tokenise the manifest code and prepare it for checking.
  #
  # path    - The path to the file as passed to puppet-lint as a String.
  # content - The data to be loaded and checked.
  #
  # Returns nothing.
  def load_data(path, content)
    SolutionLint::Data.path = path
    begin
      SolutionLint::Data.dataset = YAML.load(content)
    rescue Psych::SyntaxError => e
      problems << {
        :kind     => :error,
        :check    => :syntax,
        :message  => e,
        :line     => e.line,
        :column   => e.column,
        :fullpath => SolutionLint::Data.fullpath,
        :path     => SolutionLint::Data.path,
        :filename => SolutionLint::Data.filename,
      }
    end
  end

  # Internal: Run the lint checks over the manifest code.
  #
  # fileinfo - A Hash containing the following:
  #   :fullpath - The expanded path to the file as a String.
  #   :filename - The name of the file as a String.
  #   :path     - The original path to the file as passed to solution-lint as
  #               a String.
  # data     - The String manifest code to be checked.
  #
  # Returns an Array of problem Hashes.
  def run(fileinfo, data)
    load_data(fileinfo, data)

    checks_run = []
    enabled_checks.each do |check|
      klass = SolutionLint.configuration.check_object[check].new
      problems = klass.run

      if SolutionLint.configuration.fix
        checks_run << klass
      else
        @problems.concat(problems)
      end
    end

    checks_run.each do |check|
      @problems.concat(check.fix_problems)
    end

    @problems
  end

  # Internal: Get a list of checks that have not been disabled.
  #
  # Returns an Array of String check names.
  def enabled_checks
    @enabled_checks ||= Proc.new do
      SolutionLint.configuration.checks.select { |check|
        SolutionLint.configuration.send("#{check}_enabled?")
      }
    end.call
  end

end
