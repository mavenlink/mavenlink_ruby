require 'httparty'

module Mavenlink
  class Base
    include HTTParty
    format :json
    base_uri "https://api.mavenlink.com/api/v1/"

    attr_accessor :oath_token
    
    def initialize(oath_token)
      self.oath_token = oath_token
    end

    def get_request(path, options={})
      response = self.class.get(path, 
              :query => options, 
              :headers => { "Authorization" => "Bearer #{self.oath_token}"})
      if response.code == 200
        response.parsed_response
      else
        raise "Server error code #{response.code}: #{response.parsed_response.inspect}"
      end
    end
    
  end
end