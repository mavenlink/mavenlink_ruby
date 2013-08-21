# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mavenlink/version'

Gem::Specification.new do |spec|
  spec.name          = "mavenlink"
  spec.version       = Mavenlink::VERSION
  spec.authors       = ["Mavenlink", "Parth Gandhi"]
  spec.email         = ["opensource@mavenlink.com"]
  spec.description   = %q{A Ruby client for Mavenlink's API}
  spec.summary       = %q{}
  spec.homepage      = "https://github.com/mavenlink/mavenlink_ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "vcr", "~> 2.5"
  spec.add_development_dependency "pry"
  spec.add_runtime_dependency "httmultiparty"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "active_support"
end
