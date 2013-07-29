require 'mavenlink'
require_relative '../spec_helper'

describe Mavenlink::Client do

  before do
    @cl = Mavenlink::Client.new("76e3d087ce10f25f755968302b5e501f3d45a06447a70aa8bbdfef145014920d")  
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
    use_vcr_cassette "expense_categories"

    it "should be an array of 5 strings" do
      expense_categories = @cl.expense_categories
      expense_categories.should be_an_instance_of(Array)
      expense_categories.count.should eq(6)
    end
  end

end