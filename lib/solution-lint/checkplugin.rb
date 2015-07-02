# Public: A class that contains and provides information for the solution-lint
# checks.
#
# This class should not be used directly, but instead should be inherited.
#
# Examples
#
#   class SolutionLint::Plugin::CheckFoo < SolutionLint::CheckPlugin
#   end
class SolutionLint::CheckPlugin
  # Internal: Initialise a new SolutionLint::CheckPlugin.
  def initialize
    @problems = []
  end

  # Internal: Check the manifest for problems and filter out any problems that
  # should be ignored.
  #
  # Returns an Array of problem Hashes.
  def run
    check

#   @problems.each do |problem|
#      if SolutionLint::Data.ignore_overrides[problem[:check]].has_key?(problem[:line])
#        problem[:kind] = :ignored
#        problem[:reason] = SolutionLint::Data.ignore_overrides[problem[:check]][problem[:line]]
#        next
#       end
#   end

    @problems
  end

  # Internal: Fix any problems the check plugin has detected.
  #
  # Returns an Array of problem Hashes.
  def fix_problems
    @problems.reject { |problem| problem[:kind] == :ignored }.each do |problem|
      if self.respond_to?(:fix)
        begin
          fix(problem)
        rescue SolutionLint::NoFix
          # noop
        else
          problem[:kind] = :fixed
        end
      end
    end

    @problems
  end

  private

  # Public: Provides the tokenised manifest to the check plugins.
  #
  # Returns a Hash
  def dataset
    SolutionLint::Data.dataset
  end

  # Public: Provides the structured tree to the check plugins.
  #
  # Returns a Hash with parent keys
  def datatree
    SolutionLint::Data.datatree
  end

  # Public: Provides the expanded path of the file being analysed to check
  # plugins.
  #
  # Returns the String path.
  def fullpath
    SolutionLint::Data.fullpath
  end

  # Public: Provides the path of the file being analysed as it was provided to
  # solution-lint to the check plugins.
  #
  # Returns the String path.
  def path
    SolutionLint::Data.path
  end

  # Public: Provides the name of the file being analysed to the check plugins.
  #
  # Returns the String file name.
  def filename
    SolutionLint::Data.filename
  end

  # Internal: Prepare default problem report information.
  #
  # Returns a Hash of default problem information.
  def default_info
    @default_info ||= {
      :check      => self.class.const_get('NAME'),
      :fullpath   => fullpath,
      :path       => path,
      :filename   => filename,
    }
  end

  # Public: Report a problem with the manifest being checked.
  #
  # kind    - The Symbol problem type (:warning or :error).
  # problem - A Hash containing the attributes of the problem
  #   :message - The String message describing the problem.
  #   :line    - The Integer line number of the location of the problem.
  #   :column  - The Integer column number of the location of the problem.
  #   :check   - The Symbol name of the check that detected the problem.
  #
  # Returns nothing.
  def notify(kind, problem)
    problem[:kind] = kind
    problem.merge!(default_info) { |key, v1, v2| v1 }

    unless [:warning, :error, :fixed].include? kind
      raise ArgumentError, "unknown value passed for kind"
    end

    [:message, :line, :column, :check].each do |attr|
      unless problem.has_key? attr
        raise ArgumentError, "problem hash must contain #{attr.inspect}"
      end
    end

    @problems << problem
  end

  # Recursive find node matching key
  def nested_hash_value(obj,key)
    if obj.respond_to?(:key?) && obj.key?(key)
      obj[key]
    elsif obj.respond_to?(:each)
      r = nil
      obj.find{ |*a| r=nested_hash_value(a.last,key) }
      r
    end
  end
end
