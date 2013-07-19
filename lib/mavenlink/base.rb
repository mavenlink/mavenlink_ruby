require 'httparty'

module Mavenlink
  class Base
    include HTTParty
    format :json
    base_uri "https://api.mavenlink.com/api/v1/"

    attr_accessor :oauth_token
    
    def initialize(oauth_token)
      self.oauth_token = oauth_token
    end

    def get_request(path, options={})
      response = self.class.get(path, 
                  :query => options, 
                  :headers => { "Authorization" => "Bearer #{self.oauth_token}"})
      if response.code == 200
        response.parsed_response
      else
        raise "Server error code #{response.code}: #{response.parsed_response.inspect}"
      end
    end

    def post_request(path, options={})
      response = self.class.post(path,
                  :body => options,
                  :headers => { "Authorization" => "Bearer #{self.oauth_token}"})
      if response.code == 200
        response.parsed_response
      else
        raise "Server error code #{response.code}: #{response.parsed_response.inspect}"
      end
    end

    def put_request(path, options={})
      response = self.class.put(path,
                  :body => options,
                  :headers => { "Authorization" => "Bearer #{self.oauth_token}"})
      if response.code == 200
        response.parsed_response
      else
        raise "Server error code #{response.code}: #{response.parsed_response.inspect}"
      end
    end

    def delete_request(path)
      response = self.class.delete(path,
                  :headers => { "Authorization" => "Bearer #{self.oauth_token}"})
      if response.code == 200
        response
      else
        raise "Server error code #{response.code}: #{response.parsed_response.inspect}"
      end
    end
  end
end