# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mavenlink/version'

Gem::Specification.new do |spec|
  spec.name          = "mavenlink"
  spec.version       = Mavenlink::VERSION
  spec.authors       = ["Parth Gandhi"]
  spec.email         = ["parthgandhi@outlook.com"]
  spec.description   = %q{A Ruby client for Mavenlink's API}
  spec.summary       = %q{Mavenlink API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "pry"
  spec.add_runtime_dependency "httparty"
  spec.add_runtime_dependency "rest-client"
  spec.add_runtime_dependency "json"
end
