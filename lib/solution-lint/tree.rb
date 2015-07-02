
class SolutionLint::Tree < Hash
  # Build a simple tree to discover the parent of any key we're interested in.
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

