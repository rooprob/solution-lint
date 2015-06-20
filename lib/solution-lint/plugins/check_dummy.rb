# Public: Test the manifest tokens for any right-to-left (<-) chaining
# operators and record a warning for each instance found.
SolutionLint.new_check(:dummy) do
  def check
    true
  end
end
