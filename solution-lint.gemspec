$:.push File.expand_path("../lib", __FILE__)
require 'solution-lint/version'

Gem::Specification.new do |s|
  s.name = 'solution-lint'
  s.version = SolutionLint::VERSION
  s.homepage = 'https://github.com/rodjek/solution-lint/'
  s.summary = 'Ensure your Solution conform with the OCD style guide'
  s.description = 'Checks your Solution manifests against the OCD
  style guide and alerts you to any discrepancies.'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its', '~> 1.0'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.0'

  s.authors = ['Tim Sharpe']
  s.email = 'tim@sharpe.id.au'
end
