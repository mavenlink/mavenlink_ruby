require 'mavenlink'
require_relative '../spec_helper'

describe Mavenlink do

  before do
    @cl = Mavenlink::Client.new("999")
  end

  describe "expenses" do
    use_vcr_cassette "expenses", :record => :new_episodes

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

    it "reloads an existing workspace" do
      exp = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" })[1]
      exp_copy = @cl.expenses({:workspace_id => 3457635, :order => "date:asc" })[1]
      exp.category.should eq(exp_copy.category)
      exp.category = "Random Category Y"
      exp.save
      exp_copy.category.should_not eq(exp.category)
      exp_copy.reload
      exp_copy.category.should eq(exp.category)
    end

  end

  describe "workspaces" do
    use_vcr_cassette "workspaces", :record => :new_episodes

    it "has a creator" do
      workspace = @cl.workspaces({:search => "8105"}).first
      workspace.creator.should be_an_instance_of Mavenlink::User
      workspace.creator.full_name.should eql("Parth")
    end

    it "has participants" do
      workspace = @cl.workspaces({:search => "API Test Project"}).first
      participants = workspace.participants
      participants.should be_an_array_of(Mavenlink::User, 2)
      participants[1].full_name.should eql("API Test Account 1")
    end

    it "has a primary counterpart" do
      workspace = @cl.workspaces({:search => "API Test Project"}).first
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_an_instance_of Mavenlink::User
      primary_counterpart.full_name.should eql("API Test Account 1")
    end

    it "doesn't have a primary counterpart" do
      workspace = @cl.workspaces({:search => "8105"}).first
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_nil
    end

    it "saves an existing workspace" do
      workspace = @cl.workspaces.first
      workspace_title = "Random New Workspace"
      workspace.title = workspace_title
      workspace.save
      workspace_new = @cl.workspaces.first
      workspace_new.title.should eql("Random New Workspace")
    end

    it "reloads an existing workspace" do
      workspace = @cl.workspaces({:only => "3467515"}).first
      workspace_copy = @cl.workspaces({:only => "3467515"}).first
      workspace.title.should eq(workspace_copy.title)
      workspace.title = "Random Workspace MG"
      workspace.save
      workspace_copy.title.should_not eq(workspace.title)
      workspace_copy.reload
      workspace_copy.title.should eq(workspace_copy.title)
    end
  end

end