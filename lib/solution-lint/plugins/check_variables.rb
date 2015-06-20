# Check for variables placement and contents
SolutionLint.new_check(:variables) do

  # Build a simple tree to discover the parent of any key we're interested in.
  class Tree < Hash
    def initialize(hash = {})
      replace build_tree(hash)
    end

    private

    def build_tree(hash, parent: :root)
      hash.inject({}) do |h,(k,v)|
        h[k] = {
          parent: parent,
          value:  v.kind_of?(Hash) ? build_tree(v, parent: k) : v
        }; h
      end
    end
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

  def check
    data_tree = Tree.new(dataset)
    %w(variables environment classes).each do |key|
      unless dataset.has_key?(key)
        notify :error, {
          :message => "missing \"#{key}\" key at root",
          :line    => -1,
          :column  => -1,
          :token   => key
        }
        # search for it...
        found = nested_hash_value(data_tree, key)
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
