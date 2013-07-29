require 'mavenlink'
require_relative '../spec_helper'

describe Mavenlink::Client do

  before do
    @cl = Mavenlink::Client.new("09a072337943cdc00ceaf5b72f822a82978360e52c78ee19410491853d030b8e")  
  end

  describe "default attributes" do
    it "includes HTTParty" do
      Mavenlink::Client.should include HTTParty
    end

    it "has base url set to mavenlink api v1's endpoint" do
      Mavenlink::Client.base_uri.should eql("https://api.mavenlink.com/api/v1")
    end
  end
  
  describe "expense categories" do
    use_vcr_cassette "expense_categories", :record => :new_episodes

    it "should be an array of 6 strings" do
      expense_categories = @cl.expense_categories
      expense_categories.should be_an_array_of(String, 6)
    end
  end

  describe "users" do
    use_vcr_cassette "users", :record => :new_episodes

    it "two users exist" do
      users = @cl.users
      users.should be_an_array_of(Mavenlink::User, 2)
    end

    it "1 user exists in particular workspace" do
      users = @cl.users(:participant_in => 3448785)
      users.should be_an_array_of(Mavenlink::User, 1)
      users.first.email_address.should eql("mavenlinkapitest@gmail.com")
    end

  end

end