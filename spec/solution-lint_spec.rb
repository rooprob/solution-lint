require 'spec_helper'

describe SolutionLint do
  subject { SolutionLint.new }

  it 'should accept manifests as a string' do
    subject.code = "---\n  valid: key"
    expect(subject.code).to_not be_nil
  end

end
