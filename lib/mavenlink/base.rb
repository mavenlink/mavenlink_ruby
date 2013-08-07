require 'httmultiparty'
require 'active_support/core_ext/hash/indifferent_access'

module Mavenlink
  class Base
    include HTTMultiParty
    format :json
    base_uri "https://api.mavenlink.com/api/v1/"

    attr_accessor :oauth_token, :attributes, :associated_objects

    def initialize(oauth_token, attributes, associated_objects={})
      attributes = HashWithIndifferentAccess.new_from_hash_copying_default(attributes)
      associated_objects = HashWithIndifferentAccess.new_from_hash_copying_default(associated_objects)
      self.oauth_token = oauth_token
      self.attributes = attributes
      self.associated_objects = associated_objects
    end

    def get_request(path, options={})
      response = self.class.get(path,
                  :query => options,
                  :headers => { "Authorization" => "Bearer #{self.oauth_token}"})
      if response.code == 200
        response.parsed_response
      elsif response.code == 401
        raise AuthenticationError.new(response.parsed_response["errors"])
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
      elsif response.code == 401
        raise AuthenticationError.new(response.parsed_response["errors"])
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
      elsif response.code == 401
        raise AuthenticationError.new(response.parsed_response["errors"])
      else
        raise "Server error code #{response.code}: #{response.parsed_response.inspect}"
      end
    end

    def delete_request(path)
      response = self.class.delete(path,
                  :headers => { "Authorization" => "Bearer #{self.oauth_token}"})
      if response.code == 200 or response.code == 204
        response
      elsif response.code == 401
        raise AuthenticationError.new(response.parsed_response["errors"])
      else
        raise "Server error code #{response.code}: #{response.parsed_response.inspect}"
      end
    end

    def method_missing(method_sym, *arguments, &block)
      method = method_sym.to_s
      if attributes.has_key? method
        attributes[method]
      elsif associated_objects.has_key? method
        associated_objects[method]
      elsif attributes.has_key?(method[0...-1]) && method[-1] == '='
        self.attributes[method[0...-1]] = arguments.first
      elsif method[-5,5].eql? "_json"
        self.associated_objects[method_sym] = nil
        nil
      else
        super
      end
    end

    def parse_associated_objects(associated_hash, data, response)
      associated_objects = {}
      associated_hash.each do |name, (json_root_key, attribute_key)|
        if response.has_key? json_root_key
          if data[attribute_key].is_a?(Array)
            associated_objects["#{name}_json"] = []
            data[attribute_key].each do |id|
              associated_objects["#{name}_json"].push response[json_root_key][id]
            end
          else
            if !data.has_key? attribute_key
              associated_objects["#{name}_json"] = nil
            elsif response[json_root_key][data[attribute_key]].nil?
              associated_objects["#{name}_json"] = {}
            else  
              associated_objects["#{name}_json"] = response[json_root_key][data[attribute_key]]
            end
          end
        else
          associated_objects["#{name}_json"] = nil
        end
      end
      associated_objects
    end

  end
end