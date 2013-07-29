require_relative '../lib/mavenlink'
 
require 'rubygems'
require 'rspec'
require 'webmock/rspec'
require 'vcr'
 
#VCR config
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/'
  c.hook_into :webmock
end

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end