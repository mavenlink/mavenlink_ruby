require 'mavenlink'
require_relative '../spec_helper'

describe Mavenlink do

  before do
    @cl = Mavenlink::Client.new("999")
  end

  vcr_options = {cassette_name: 'expenses', :record => :new_episodes}
  describe "expenses", vcr: vcr_options do

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

    it "reloads an existing expense" do
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

  vcr_options = {cassette_name: 'workspaces', :record => :new_episodes}
  describe "workspaces", vcr: vcr_options do

    it "has a creator" do
      workspace = @cl.workspaces({:search => "8105", :include => "all"}).first
      workspace.creator.should be_an_instance_of Mavenlink::User
      workspace.creator.full_name.should eql("Parth")
    end

    it "has participants" do
      workspace = @cl.workspaces({:search => "API Test Project", :include => "all"}).first
      participants = workspace.participants
      participants.should be_an_array_of(Mavenlink::User, 2)
      participants[1].full_name.should eql("API Test Account 1")
    end

    it "has a primary counterpart" do
      workspace = @cl.workspaces({:search => "API Test Project", :include => "all"}).first
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_an_instance_of Mavenlink::User
      primary_counterpart.full_name.should eql("API Test Account 1")
    end

    it "doesn't have a primary counterpart" do
      workspace = @cl.workspaces({:search => "8105", :include => "all"}).first
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_nil
    end

    it "saves an existing workspace" do
      workspace = @cl.workspaces({:include => "all"}).first
      workspace_title = "Random New Workspace"
      workspace.title = workspace_title
      workspace.save
      workspace_new = @cl.workspaces({:include => "all"}).first
      workspace_new.title.should eql("Random New Workspace")
    end

    it "reloads an existing workspace" do
      workspace = @cl.workspaces({:only => "3467515", :include => "all"}).first
      workspace_copy = @cl.workspaces({:only => "3467515", :include => "all"}).first
      workspace.title.should eq(workspace_copy.title)
      workspace.title = "Random Workspace MG"
      workspace.save
      workspace_copy.title.should_not eq(workspace.title)
      workspace_copy.reload("all")
      workspace_copy.title.should eq(workspace_copy.title)
    end
  end

  vcr_options = {cassette_name: 'invoices', :record => :new_episodes}
  describe "invoices", vcr: vcr_options do

    it "has time entries" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280315", :include => "all"}).first
      time_entries = inv.time_entries
      time_entries.should be_an_array_of(Mavenlink::TimeEntry, 2)
      time_entry = time_entries[1]
      time_entry.notes.should eql("Additional Notes Example")
      time_entry.time_in_minutes.should eq(300)
    end

    it "has expenses" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280315", :include => "all"}).first
      expenses = inv.expenses
      expenses.should be_an_array_of(Mavenlink::Expense, 1)
      exp = expenses.first
      exp.is_invoiced.should be_true
      exp.notes.should eql("Expense Notes")
    end

    it "returns empty array when no expenses exist" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335",:include => "all"}).first
      inv.expenses.should be_empty
    end

    it "has additional items" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335",:include => "all"}).first
      additional_items = inv.additional_items
      additional_items.should be_an_instance_of Array
      itm = additional_items.first
      itm["notes"].should eql("Additional Item 1")
    end

    it "has workspaces" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335", :include => "all"}).first
      workspaces = inv.workspaces
      workspaces.should be_an_array_of(Mavenlink::Workspace, 1)
      wks = workspaces.first
      wks.title.should eql("Random Workspace MG")
      wks.archived.should be_false
    end

    it "has a user" do
      inv = @cl.invoices({:workspace_id => "3457635,3467515", :only => "280335", :include => "all"}).first
      user = inv.user
      user.should be_an_instance_of Mavenlink::User
      user.full_name.should eql("Parth")
      user.headline.should be_nil
    end

  end

  vcr_options = {cassette_name: 'time_entries', :record => :new_episodes}
  describe "time_entries", vcr: vcr_options do

    it "has a user" do
      entries = @cl.time_entries({:workspace_id => 3457635, :include => "all"})
      entry = entries.first
      user = entry.user
      user.should be_an_instance_of Mavenlink::User
      user.full_name.should eql("Parth")
    end

    it "has a workspace" do
      entry = @cl.time_entries({:workspace_id => 3457635, :include => "all"}).first
      workspace = entry.workspace
      workspace.should be_an_instance_of Mavenlink::Workspace
      workspace.title.should eql("Random New Workspace")
    end

    it "has a story" do
      entry = @cl.time_entries({:workspace_id => 3457635, :include => "all"}).first
      story = entry.story
      story.should be_an_instance_of Mavenlink::Post
      story.created_at.should eql("2013-07-29T19:36:48-07:00")
    end

    it "returns nil if no story exists" do
      entry = @cl.time_entries({:only => 8590085,:include => "all"}).first
      story = entry.story
      story.should be_nil
    end

    it "can be deleted" do
      ent = @cl.time_entries({:workspace_id => 3467515, :order => "date:asc",:include => "all" }).first
      ent.delete
      new_entries = @cl.expenses({:workspace_id => 3467515, :order => "date:asc" })
      new_entries.should be_empty
    end

    it "can be saved" do
      ent = @cl.time_entries({:only => 8590085, :include => "all"}).first
      ent.time_in_minutes = 75
      ent.save
      new_ent = @cl.time_entries({:only => ent.id, :include => "all"}).first
      new_ent.time_in_minutes.should eq(75)
    end

  end

  vcr_options = {cassette_name: 'stories', :record => :new_episodes}
  describe "stories", vcr: vcr_options do

    it "has a workspace" do
      story = @cl.stories({:workspace_id => 3403465, :include => "all"}).first
      workspace = story.workspace
      workspace.should be_an_instance_of Mavenlink::Workspace
      workspace.title.should eql("8105 Project")
    end

    it "has a parent" do
      story = @cl.stories({:workspace_id => 3403465, :include => "all"}).last
      parent = story.parent_story
      parent.should be_an_instance_of Mavenlink::Story
      parent.title.should eql("Example Task")
    end

    it "returns nil if no parent" do
      story = @cl.stories({:workspace_id => 3403465, :include => "all"}).first
      story.parent_story.should be_nil
    end

    it "has assignees" do
      story = @cl.stories({:workspace_id => 3403465, :include => "all"})[1]
      assignees = story.assignees
      assignees.should be_an_array_of(Mavenlink::User, 1)
      assignees.first.full_name.should eql("Parth")
    end

    it "returns [] if no assignees exist" do
      story = @cl.stories({:workspace_id => 3403465, :include => "all"}).first
      story.assignees.should be_empty
    end

    it "has sub_stories" do
      story = @cl.stories({:workspace_id => 3403465, :include => "all"})[1]
      sub_stories = story.sub_stories
      sub_stories.should be_an_array_of(Mavenlink::Story, 1)
      sub_stories.first.title.should eql("Example sub-task")
    end

    it "has tags" do
      story = @cl.stories({:workspace_id => 3457635, :include => "all"}).first
      tags = story.tags
      tags.should be_an_array_of(String, 2)
    end

    it "can be deleted" do
      story = @cl.stories({:workspace_id => 3484825, :include => "all"}).first
      story.deleted_at.should be_nil
      story.delete
      deleted_story = @cl.stories({:search => "Test Project Meh", :include => "all"}).first
      deleted_story.deleted_at.should_not be_nil
    end

    it "can be saved" do
      story = @cl.stories({:workspace_id => 3403465, :include => "all"}).first
      story.percentage_complete.should eq(0)
      story.percentage_complete = 10
      story.save
      story = @cl.stories({:workspace_id => 3403465, :only => 26593185,:include => "all"}).first
      story.percentage_complete.should eq(10)
    end
  end

  vcr_options = {cassette_name: 'posts', :record => :new_episodes}
  describe "posts", vcr: vcr_options do

    it "has a parent_post" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"})[1]
      parent_post = post.parent_post
      parent_post.should be_an_instance_of Mavenlink::Post
      parent_post.message.should eql("TestPost2")
    end

    it "returns nil if no parent post" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"}).last
      post.parent_post.should be_nil
    end

    it "has a user" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"}).last
      user = post.user
      user.should be_an_instance_of Mavenlink::User
      user.full_name.should eql("Parth")
    end

    it "has a workspace" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"}).last
      workspace = post.workspace
      workspace.should be_an_instance_of Mavenlink::Workspace
      workspace.title.should eql("Random New Workspace")
    end

    it "has a story" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"}).first
      story = post.story
      story.should be_an_instance_of Mavenlink::Story
      story.title.should eql("New Task")
    end

    it "has replies" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"}).first
      replies = post.replies
      replies.should be_an_array_of(Mavenlink::Post, 1)
      replies.first.message.should eql("TestReplyPost1")
    end

    it "has recipients" do
      post = @cl.posts({:workspace_id => 3457635, :only => 26239615, :include => "all"}).first
      recipients = post.recipients
      recipients.should be_an_array_of(Mavenlink::User, 2)
    end

    it "has a newest reply" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"}).first
      newest_reply = post.newest_reply
      newest_reply.should be_an_instance_of Mavenlink::Post
    end

    it "has a newest user" do
      post = @cl.posts({:workspace_id => 3457635, :include => "all"}).first
      newest_reply_user = post.newest_reply_user
      newest_reply_user.should be_an_instance_of Mavenlink::User
    end

    it "has attachments" do
      post = @cl.posts({:workspace_id => 3457635, :only => 26236765, :include => "all"}).first
      attachments = post.attachments
      attachments.should be_an_array_of(Mavenlink::Attachment, 1)
      attachments.first.file_name.should eql("png.png")
    end
  end

  vcr_options = {cassette_name: 'nested_objects', :record => :new_episodes}
  describe "nested attribute objects", vcr: vcr_options do

    it "can load attribute objects using array as include" do
      workspace = @cl.workspaces({:search => "Test", :include => ["creator"]}).first
      workspace.should_not_receive(:reload).with("creator").and_call_original
      creator = workspace.creator
      creator.should be_an_instance_of Mavenlink::User
      creator.full_name.should eql("Parth")
    end

    it "can reload using array of attributes" do
      workspace = @cl.workspaces({:search => "8105"}).first
      workspace.should_receive(:reload).with(["creator"]).and_call_original
      workspace.reload(["creator"])
      creator = workspace.creator
      creator.should be_an_instance_of Mavenlink::User
    end

    it "workspace should include creator" do
      workspace = @cl.workspaces({:search => "8105", :include => "creator"}).first
      workspace.should_not_receive(:reload).with("creator").and_call_original
      creator = workspace.creator
      creator.should be_an_instance_of Mavenlink::User
      creator.full_name.should eql("Parth")
    end

    it "workspace should reload creator when not included" do
      workspace = @cl.workspaces({:search => "8105"}).first
      workspace.should_receive(:reload).with("creator").and_call_original
      creator = workspace.creator
      creator.should be_an_instance_of Mavenlink::User
      creator.full_name.should eql("Parth")
      workspace.participants_json.should be_nil
    end

    it "workspace should not call reload twice with no primary counterpart" do
      workspace = @cl.workspaces({:search => "8105"}).first
      workspace.should_receive(:reload).with("primary_counterpart").once.and_call_original
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_nil

      # Second call to primary counterpart should not call reload
      primary_counterpart = workspace.primary_counterpart
      primary_counterpart.should be_nil
    end

    it "entry should include workspace" do
      entry = @cl.time_entries({:workspace_id => 3457635, :include => "workspace"}).first
      entry.should_not_receive(:reload).with("workspace").and_call_original
      workspace = entry.workspace
      workspace.should be_an_instance_of Mavenlink::Workspace
    end

    it "entry should reload workspace when not included" do
      entry = @cl.time_entries({:workspace_id => 3457635}).first
      entry.should_receive(:reload).with("workspace").once.and_call_original
      workspace = entry.workspace
      workspace.should be_an_instance_of Mavenlink::Workspace
      entry.user_json.should be_nil
    end

    it "entry should have a fully functional nested workspace" do
      entry = @cl.time_entries({:workspace_id => 3457635, :include => "workspace"}).first
      workspace = entry.workspace
      workspace.should_receive(:reload).with("creator").and_call_original
      creator = workspace.creator
      creator.should be_an_instance_of Mavenlink::User
      creator.full_name.should eql("Parth")
    end

  end

end