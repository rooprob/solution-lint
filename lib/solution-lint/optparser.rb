require 'optparse'

# Public: Contains the solution-lint option parser so that it can be used easily
# in multiple places.
class SolutionLint::OptParser
  HELP_TEXT = <<-EOF
    solution-lint

    Basic Command Line Usage:
      solution-lint [OPTIONS] PATH

            PATH                         The path to the content

    Option:
  EOF

  # Public: Initialise a new solution-lint OptionParser.
  #
  # Returns an OptionParser object.
  def self.build
    OptionParser.new do |opts|
      opts.banner = HELP_TEXT

      opts.on('--version', 'Display the current version.') do
        SolutionLint.configuration.display_version = true
      end

      opts.on('-c', '--config FILE', 'Load solution-lint options from file.') do |file|
        opts.load(file)
      end

      opts.on('--with-context', 'Show where the problem is.') do
        SolutionLint.configuration.with_context = true
      end

      opts.on('--with-filename', 'Display the filename before the warning.') do
        SolutionLint.configuration.with_filename = true
      end

      opts.on('--fail-on-warnings', 'Return a non-zero exit status for warnings') do
        SolutionLint.configuration.fail_on_warnings = true
      end

      opts.on('--error-level LEVEL', [:all, :warning, :error],
              'The level of error to return (warning, error or all).') do |el|
        SolutionLint.configuration.error_level = el
      end

      opts.on('--show-ignored', 'Show problems that have been ignored by control comments') do
        SolutionLint.configuration.show_ignored = true
      end

      opts.on('--relative', 'Compare module layout relative to the module root') do
        SolutionLint.configuration.relative = true
      end

      opts.on('-l', '--load FILE', 'Load a file containing custom solution-lint checks.') do |f|
        load f
      end

      opts.on('--load-from-solution SOLUTIONPATH', 'Load plugins from the given solution path.') do |path|
        path.split(':').each do |p|
          Dir["#{p}/*/lib/solution-lint/plugins/*.rb"].each do |file|
            load file
          end
        end
      end

      opts.on('--log-format FORMAT',
              'Change the log format.', 'Overrides --with-filename.',
              'The following placeholders can be used:',
              '%{filename} - Filename without path.',
              '%{path}     - Path as provided to solution-lint.',
              '%{fullpath} - Expanded path to the file.',
              '%{line}     - Line number.',
              '%{column}   - Column number.',
              '%{kind}     - The kind of message (warning, error).',
              '%{KIND}     - Uppercase version of %{kind}.',
              '%{check}    - The name of the check.',
              '%{message}  - The message.'
      ) do |format|
        if format.include?('%{linenumber}')
          $stderr.puts "DEPRECATION: Please use %{line} instead of %{linenumber}"
        end
        SolutionLint.configuration.log_format = format
      end

      opts.separator ''
      opts.separator '    Checks:'

      opts.on('--only-checks CHECKS', 'A comma separated list of checks that should be run') do |checks|
        enable_checks = checks.split(',').map(&:to_sym)
        (SolutionLint.configuration.checks - enable_checks).each do |check|
          SolutionLint.configuration.send("disable_#{check}")
        end
      end

      SolutionLint.configuration.checks.each do |check|
        opts.on("--no-#{check}-check", "Skip the #{check} check.") do
          SolutionLint.configuration.send("disable_#{check}")
        end
      end

      opts.load('/etc/solution-lint.rc')
      begin
        opts.load(File.expand_path('~/.solution-lint.rc')) if ENV['HOME']
      rescue Errno::EACCES
        # silently skip loading this file if HOME is set to a directory that
        # the user doesn't have read access to.
      end
      opts.load('.solution-lint.rc')
    end
  end
end
