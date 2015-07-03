require 'spec_helper'
require 'yaml'

describe SolutionLint::Data do

  context 'basic string value test' do
    it '.dataset has :a set to :foo' do
      SolutionLint::Data.dataset = "---\n  a:\n    :foo\n  b: :bar\n"
      expect(SolutionLint::Data.dataset["a"]).to be(:foo)
    end
  end

  context 'basic string value test' do
    it '.dataset has :a set to nil' do
      SolutionLint::Data.dataset = "---\n  a:\n    nil\n  b: nil\n"
      expect(SolutionLint::Data.dataset["a"]).to eq("nil")
    end
  end
end
