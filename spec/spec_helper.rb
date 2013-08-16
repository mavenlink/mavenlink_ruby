require_relative '../lib/mavenlink'
require_relative 'support/rspec_matchers'
require_relative 'support/httmultiparty'
 
require 'rubygems'
require 'rspec'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end