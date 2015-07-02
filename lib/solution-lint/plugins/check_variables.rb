# Check for variables placement and contents
SolutionLint.new_check(:variables) do

  def check
    %w(variables environment classes).each do |key|
      unless dataset.has_key?(key)
        notify :error, {
          :message => "missing \"#{key}\" key at root",
          :line    => -1,
          :column  => -1,
          :token   => key
        }
        # search for it...
        found = nested_hash_value(datatree, key)
        if found
          notify :warning, {
            :message => "found \"#{key}\" key at \"#{found[:parent]}\", should be in root",
            :line    => -1,
            :column  => -1,
            :token   => found[:parent]
          }
        end
      end
    end
  end
end
