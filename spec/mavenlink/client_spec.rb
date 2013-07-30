require 'mavenlink'
require_relative '../spec_helper'

describe Mavenlink::Client do

  before do
    @cl = Mavenlink::Client.new("999")
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
      users = @cl.users({:participant_in => 3448785})
      users.should be_an_array_of(Mavenlink::User, 1)
      users.first.email_address.should eql("mavenlinkapitest@gmail.com")
    end

  end

  describe "expenses" do
    use_vcr_cassette "expenses", :record => :new_episodes

    it "two expenses exist" do
      expenses = @cl.expenses({:workspace_id => 3457635})
      expenses.should be_an_array_of(Mavenlink::Expense, 2)
      expenses[0].is_billable.should be_true
      expenses[1].is_billable.should be_false
    end

    it "expenses are ordered" do
      expenses = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" })
      expenses[0].date.should be_before expenses[1].date
    end

    it "no expenses with invalid workspace_id" do
      expenses = @cl.expenses({:workspace_id => 111})
      expenses.should be_empty
    end

    it "create a new expense" do
      @cl.create_expense({ :workspace_id => 3403465,
                            :date => "2012/01/01",
                            :category => "Travel",
                            :amount_in_cents => 100 
                          }).should be_an_instance_of Mavenlink::Expense

    end

    it "raises error when creating workspace without required options" do
      expect {@cl.create_expense({:workspace_id => 3403465,
                                  :date => "2012/01/01",
                                  :category => "Travel",
                                  }) }.to raise_error
    end

    it "save an existing expense" do
      exp = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" }).first
      exp.category = "Random Category X"
      exp.save
      saved_exp = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" }).first
      saved_exp.category.should eql("Random Category X")
    end

    it "delete an existing expense" do
      exp = @cl.expenses({:workspace_id => 3403465, :order => "date:asc" }).first
      exp_id = exp.id
      exp.delete
      new_exp = @cl.expenses({:workspace_id => 3403465, :order => "date:asc" }).first
      new_exp.id.should_not eq(exp_id)
    end

  end

end