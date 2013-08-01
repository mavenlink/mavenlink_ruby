module Mavenlink

  class Error < StandardError
    attr_accessor :errors
    def initialize(errors)
      self.errors = errors
    end
  end

  class AuthenticationError < Error; end
  class InvalidParametersError < Error; end

end