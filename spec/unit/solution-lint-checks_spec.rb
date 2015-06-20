require 'spec_helper'

describe SolutionLint::Checks do
  subject { SolutionLint::Checks.new }

  it 'should have no problems when loading valid file' do
    linter = SolutionLint.new
    linter.file = valid_file_path
    subject.load_data(linter.path, linter.content)
    expect(subject.problems.length).to eq(0)
  end

  it 'should have one problem when loading invalid file' do
    linter = SolutionLint.new
    linter.file = fail_file_path
    subject.load_data(linter.path, linter.content)
    expect(subject.problems.length).to eq(1)
  end

end
