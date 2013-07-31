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

    it "get a user by id" do
      users = @cl.users(:only => "3847595")
      users.should be_an_array_of Mavenlink::User, 1
      users.first.full_name.should eql("API Test Account 1")
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

    it "raises error when creating expense without required options" do
      expect {@cl.create_expense({:workspace_id => 3403465,
                                  :date => "2012/01/01",
                                  :category => "Travel",
                                  }) }.to raise_error
    end

  end

  describe "workspaces" do
    use_vcr_cassette "workspaces", :record => :new_episodes

    it "3 active workspaces should exist" do
      workspaces = @cl.workspaces
      workspaces.should be_an_array_of(Mavenlink::Workspace, 3)
      workspaces.first.title.should eql("API Test Project")
    end

    it "workspaces can be filtered" do
      workspaces = @cl.workspaces({:include_archived => true})
      workspaces.should be_an_array_of(Mavenlink::Workspace, 4)
    end

    it "workspaces can be searched" do
      workspaces = @cl.workspaces({:search => "API Test Project"})
      workspaces.should be_an_array_of(Mavenlink::Workspace, 1)
      workspaces.first.title.should eql("API Test Project")
    end

    it "create a new workspace" do
      workspaces = @cl.workspaces({:search => "Random Workspace X"})
      workspaces.should be_empty
      @cl.create_workspace({ :title => "Random Workspace X",
                             :creator_role => "maven"
                           }).should be_an_instance_of Mavenlink::Workspace

      workspaces = @cl.workspaces({:search => "Random Workspace"})
      workspaces.should be_an_array_of(Mavenlink::Workspace, 1)
      workspaces.first.title.should eql("Random Workspace X")
    end

    it "raises error when creating workspace without required options" do
       expect { @cl.create_workspace({ :title => "Random Workspace X",
                                       :creator_role => "invalid"
                                       }) }.to raise_error
    end
  end

  describe "invoices" do
    use_vcr_cassette "invoices", :record => :new_episodes

    it "2 invoices exist" do
      invoices = @cl.invoices({:workspace_id => "3457635,3467515"})
      invoices.should be_an_array_of(Mavenlink::Invoice, 2)
      invoices.first.status.should eql("accepted payment")
      invoices[1].status.should eql("new")
    end

    it "invoices can be filtered" do
      invoices = @cl.invoices({:workspace_id => "3457635,3467515", :paid => "true"})
      invoices.should be_an_array_of(Mavenlink::Invoice, 1)
    end

    it "can get invoice by id" do
      invoices = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280315"})
      invoices.should be_an_array_of(Mavenlink::Invoice, 1)
      invoices.first.status.should eql("new")
    end
  end

  describe "time_entries" do
    use_vcr_cassette "time_entries", :record => :new_episodes

    it "time entries exist" do
      time_entries = @cl.time_entries({:workspace_id => 3457635})
      time_entries.should be_an_array_of(Mavenlink::TimeEntry, 2)
      entry = time_entries.first
      entry.billable.should be_false
      entry.date_performed.should eql("2013-07-03")
    end

    it "can be filtered and ordered" do
      time_entries = @cl.time_entries({:workspace_id => 3457635, :order => "created_at:asc" })
      time_entries[0].date_performed.should be_before time_entries[1].date_performed
    end

    it "create a new time entry" do
      time_entries = @cl.time_entries({:workspace_id => 3403465})
      time_entries.should be_empty
      ent = @cl.create_time_entry({
                            :workspace_id => 3467515,
                            :date_performed => "2013-07-04",
                            :time_in_minutes => 34
                            })
      ent.should be_an_instance_of Mavenlink::TimeEntry
      time_entries = @cl.time_entries({:workspace_id => 3467515})
      time_entries.should be_an_array_of(Mavenlink::TimeEntry, 1)
    end

    it "raises error when creating entry without required options" do
      expect {@cl.create_time_entry({
                                    :workspace_id => 3467515,
                                    :date_performed => "2013-07-04",
                                    })}.to raise_error
    end
  end

end