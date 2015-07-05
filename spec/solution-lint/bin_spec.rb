require 'spec_helper'
require 'rspec/mocks'
require 'optparse'

class CommandRun
  attr_accessor :stdout, :stderr, :exitstatus

  def initialize(args)
    out = StringIO.new
    err = StringIO.new

    $stdout = out
    $stderr = err

    SolutionLint.configuration.defaults
    @exitstatus = SolutionLint::Bin.new(args).run
    SolutionLint.configuration.defaults

    @stdout = out.string.strip
    @stderr = err.string.strip

    $stdout = STDOUT
    $stderr = STDERR
  end
end

describe SolutionLint::Bin do
  subject do
    if args.is_a? Array
      sane_args = args
    else
      sane_args = [args]
    end

    CommandRun.new(sane_args)
  end

  context 'when running normally' do
    let(:args) { [ 'spec/fixtures/test/valid.yaml' ] }

    its(:exitstatus) { is_expected.to eq(0) }
  end

  context 'when running without arguments' do
    let(:args) { [] }

    its(:exitstatus) { is_expected.to eq(1) }
  end

  context 'when passed multiple files' do
    let(:args) { [
      'spec/fixtures/test/warning.yaml',
      'spec/fixtures/test/fail.yaml',
    ] }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to match(%r{ERROR: Syntax error}) }
  end

  context 'when passed a malformed file' do
    let(:args) { 'spec/fixtures/test/malformed.yaml' }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to match('ERROR: Syntax error') }
  end

  context 'when limited to errors only' do
    let(:args) { [
      '--error-level', 'error',
      'spec/fixtures/test/warning.yaml',
      'spec/fixtures/test/fail.yaml',
    ] }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to match(/^#{args.last} - ERROR/) }
  end

  context 'when limited to warnings only', pending: true do
    let(:args) { [
      '--error-level', 'warning',
      'spec/fixtures/test/warning.yaml',
      'spec/fixtures/test/fail.yaml',
    ] }

    it 'exitstatus should.be eq(1)'
    it 'stdout should match WARNING'
  end

  context 'when specifying a specific check to run', pending: true do
    let(:args) { [
      '--only-check', 'parameter_order',
      'spec/fixtures/test/warning.yaml',
      'spec/fixtures/test/fail.yaml',
    ] }

    it 'exitstatus should.be eq(1)'
    it 'stdout should match ERROR'
  end

  context 'when asked to display filenames ' do
    let(:args) { ['--with-filename', 'spec/fixtures/test/fail.yaml'] }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to match(%r{^spec/fixtures/test/fail\.yaml -}) }
  end

  context 'when asked to provide context to problems' do
    let(:args) { [
      '--with-context',
      'spec/fixtures/test/malformed.yaml',
    ] }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to eq([
      'ERROR: Syntax error (malformed.yaml): did not find expected \',\' or \']\' while parsing a flow sequence at line 2 column 13 on line 2',
      '',
      "  test_key: [ one, two three",
      '            ^',
    ].join("\n"))
    }
  end

  context 'when asked to fail on warnings', pending: true do
    let(:args) { [
      '--fail-on-warnings',
      'spec/fixtures/test/warning.yaml',
    ] }

    it 'exitstatus should.be eq(1)'
    it 'stdout should match'
  end

  context 'when used with an invalid option' do
    let(:args) { '--foo-bar-baz' }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to match(/invalid option/) }
  end

  context 'when passed a file that does not exist' do
    let(:args) { 'spec/fixtures/test/enoent.yaml' }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to match(/specified file does not exist/) }
  end

  context 'when passed a directory' do
    let(:args) { 'spec/fixtures/' }

    its(:exitstatus) { is_expected.to eq(1) }
    its(:stdout) { is_expected.to match(/ERROR/) }
  end

  context 'when disabling a check', pending: true do
    let(:args) { [
      '--no-dummy-check',
      'spec/fixtures/test/fail.yaml'
    ] }

    its(:exitstatus) { is_expected.to eq(0) }
    it 'stdout should match'
  end

  context 'when changing the log format' do
    context 'to print %{filename}' do
      let(:args) { [
        '--log-format', '%{filename}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('fail.yaml') }
    end

    context 'to print %{path}' do
      let(:args) { [
        '--log-format', '%{path}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('spec/fixtures/test/fail.yaml') }
    end

    context 'to print %{fullpath}' do
      let(:args) { [
        '--log-format', '%{fullpath}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) {
        is_expected.to match(%r{^/.+/spec/fixtures/test/fail\.yaml$})
      }
    end

    context 'to print %{linenumber}' do
      let(:args) { [
        '--log-format', '%{linenumber}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('3') }
      its(:stderr) { is_expected.to eq('DEPRECATION: Please use %{line} instead of %{linenumber}') }
    end

    context 'to print %{line}' do
      let(:args) { [
        '--log-format', '%{line}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('3') }
    end

    context 'to print %{kind}' do
      let(:args) { [
        '--log-format', '%{kind}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('error') }
    end

    context 'to print %{KIND}' do
      let(:args) { [
        '--log-format', '%{KIND}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('ERROR') }
    end

    context 'to print %{check}' do
      let(:args) { [
        '--log-format', '%{check}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('syntax') }
    end

    context 'to print %{message}' do
      let(:args) { [
        '--log-format', '%{message}',
        'spec/fixtures/test/fail.yaml'
      ] }

      its(:exitstatus) { is_expected.to eq(1) }
      its(:stdout) { is_expected.to eq('Syntax error (fail.yaml): could not find expected \':\' while scanning a simple key at line 3 column 3') }
    end
  end

  context 'when hiding ignored problems', pending: true do
    let(:args) { [
      'spec/fixtures/test/ignore.yaml'
    ] }

    it 'exitstatus 0'
    it 'stdout not to match IGNORED'
  end

  context 'when showing ignored problems', pending: true do
    let(:args) { [
      '--show-ignored',
      'spec/fixtures/test/ignore.yaml',
    ] }
    it 'exitstatus 0'
    it 'stdout should match IGNORED'
  end

  context 'when showing ignored problems with a reason', pending: true do
    let(:args) { [
      '--show-ignored',
      'spec/fixtures/test/ignore_reason.yaml',
    ] }

    it 'exitstatus 0'
    it 'stdout should match IGNORED: double quoted string ...'
  end

  context 'ignoring multiple checks on a line', pending: true do
    let(:args) { [
      'spec/fixtures/test/ignore_multiple_line.yaml',
    ] }

    its(:exitstatus) { is_expected.to eq(0) }
  end

  context 'ignoring multiple checks in a block', pending: true do
    let(:args) { [
      'spec/fixtures/test/ignore_multiple_block.yaml',
    ] }

    its(:exitstatus) { is_expected.to eq(0) }
    its(:stdout) { is_expected.to match(/^.*line 6$/) }
  end
end
