require 'pathname'

class SolutionLint
  # Public: Various methods that implement solution-lint's plugin system
  #
  # Examples
  #
  #   SolutionLint::Plugins.load_spec_helper
  class Plugins
    # Internal: Find any gems containing solution-lint plugins and load them.
    #
    # Returns nothing.
    def self.load_from_gems
      gem_directories.select { |path|
        (path + 'solution-lint/plugins').directory?
      }.each do |gem_path|
        Dir["#{(gem_path + 'solution-lint/plugins').to_s}/*.rb"].each do |file|
          load file
        end
      end
    end

    # Public: Load the solution-lint spec_helper.rb
    #
    # Returns nothings.
    def self.load_spec_helper
      gemspec = gemspecs.select { |spec| spec.name == 'solution-lint' }.first
      load Pathname.new(gemspec.full_gem_path) + 'spec/spec_helper.rb'
    end
  private
    # Internal: Check if RubyGems is loaded and available.
    #
    # Returns true if RubyGems is available, false if not.
    def self.has_rubygems?
      defined? ::Gem
    end

    # Internal: Retrieve a list of avaliable gemspecs.
    #
    # Returns an Array of Gem::Specification objects.
    def self.gemspecs
      @gemspecs ||= if Gem::Specification.respond_to?(:latest_specs)
        Gem::Specification.latest_specs
      else
        Gem.searcher.init_gemspecs
      end
    end

    # Internal: Retrieve a list of available gem paths from RubyGems.
    #
    # Returns an Array of Pathname objects.
    def self.gem_directories
      if has_rubygems?
        gemspecs.reject { |spec| spec.name == 'solution-lint' }.map do |spec|
          Pathname.new(spec.full_gem_path) + 'lib'
        end
      else
        []
      end
    end
  end
end

require 'solution-lint/plugins/check_dummy'
require 'solution-lint/plugins/check_variables'

SolutionLint::Plugins.load_from_gems
