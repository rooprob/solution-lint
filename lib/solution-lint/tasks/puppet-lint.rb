require 'solution-lint'
require 'solution-lint/optparser'
require 'rake'
require 'rake/tasklib'

class SolutionLint
  # Public: A Rake task that can be loaded and used with everything you need.
  #
  # Examples
  #
  #   require 'solution-lint'
  #   SolutionLint::RakeTask.new
  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    DEFAULT_PATTERN = '**/*.yaml'

    attr_accessor :name
    attr_accessor :pattern
    attr_accessor :ignore_paths
    attr_accessor :with_filename
    attr_accessor :disable_checks
    attr_accessor :fail_on_warnings
    attr_accessor :error_level
    attr_accessor :log_format
    attr_accessor :with_context
    attr_accessor :fix
    attr_accessor :show_ignored
    attr_accessor :relative

    # Public: Initialise a new SolutionLint::RakeTask.
    #
    # args - Not used.
    #
    # Example
    #
    #   SolutionLint::RakeTask.new
    def initialize(*args, &task_block)
      @name = args.shift || :lint
      @pattern = DEFAULT_PATTERN
      @with_filename = true
      @disable_checks = []
      @ignore_paths = []

      define(args, &task_block)
    end

    def define(args, &task_block)
      desc 'Run solution-lint'

      task_block.call(*[self, args].slice(0, task_block.arity)) if task_block

      # clear any (auto-)pre-existing task
      Rake::Task[@name].clear if Rake::Task.task_defined?(@name)
      task @name do
        SolutionLint::OptParser.build

        Array(@disable_checks).each do |check|
          SolutionLint.configuration.send("disable_#{check}")
        end

        %w{with_filename fail_on_warnings error_level log_format with_context fix show_ignored relative}.each do |config|
          value = instance_variable_get("@#{config}")
          SolutionLint.configuration.send("#{config}=".to_sym, value) unless value.nil?
        end

        if SolutionLint.configuration.ignore_paths
          @ignore_paths = SolutionLint.configuration.ignore_paths
        end

        RakeFileUtils.send(:verbose, true) do
          linter = SolutionLint.new
          matched_files = FileList[@pattern]

          matched_files = matched_files.exclude(*@ignore_paths)

          matched_files.to_a.each do |solution_file|
            linter.file = solution_file
            linter.run
            linter.print_problems
          end
          abort if linter.errors? || (
            linter.warnings? && SolutionLint.configuration.fail_on_warnings
          )
        end
      end
    end
  end
end

SolutionLint::RakeTask.new
