# Public: Test the manifest tokens for any right-to-left (<-) chaining
# operators and record a warning for each instance found.
SolutionLint.new_check(:dummy) do
  puts "I am a new check!"
  def check
    puts "stuff looks like #{tokens}"
    notify :warning, {
      :message =>  'sample message',
      :line    => 1,
      :column  => 1
    }
  end
end
