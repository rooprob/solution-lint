require 'spec_helper'

describe SolutionLint do
  subject { SolutionLint.new }

  it 'should have empty path when file does not exist' do
    subject.file = "path/to/does-not-exist.yaml"
    expect(subject.path).to be_nil
  end

  it 'should load file when file does exist' do
    subject.file = valid_file_path
    puts valid_file_path

    expect(subject.path).to_not be_nil
  end

  it 'should load file when file does exist (invalid file)' do
    subject.file = fail_file_path
    puts valid_file_path

    expect(subject.path).to_not be_nil
  end

end
