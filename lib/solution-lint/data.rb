require 'singleton'
require 'set'
require 'yaml'
require 'solution-lint/tree'

# Public: A singleton class storing all the information about the manifest
# being analysed.
class SolutionLint::Data
  include Singleton

  class << self
    # Internal: Get/Set the full expanded path to the manifest file being
    # checked.
    attr_reader :path, :fullpath, :filename

    # Internal: Get/Set the dataset, read by YAML
    attr_accessor :dataset
    attr_accessor :datatree
    attr_accessor :failed
    attr_accessor :problems

    def dataset=(content)
      @problems = []
      @failed = false
      begin
        @dataset = YAML.load(content, @filename)
        @datatree = SolutionLint::Tree.new(dataset)
      rescue Psych::SyntaxError => e
        @failed = true
        @problems << {
          :kind     => :error,
          :check    => :syntax,
          :message  => "Syntax error #{e}",
          :line     => e.line,
          :column   => e.column,
          :fullpath => @fullpath,
          :path     => @path,
          :filename => @filename,
        }
      end
      @failed
    end

    # Internal: Store the path to the manifest file and populate fullpath and
    # filename.
    #
    # val - The path to the file as a String.
    #
    # Returns nothing.
    def path=(val)
      @path = val
      if val.nil?
        @fullpath = nil
        @filename = nil
      else
        @fullpath = File.expand_path(val, ENV['PWD'])
        @filename = File.basename(val)
      end
    end

  end
end
