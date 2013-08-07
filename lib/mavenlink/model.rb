module Mavenlink

  class User < Base
  end

  class Asset < Base

    def save
      options = {}
      options["asset[filename]"] = self.file_name
      put_request("/assets/#{id}.json", options)
    end

    def delete
      delete_request("/assets/#{id}.json")
    end
  end

  class Workspace < Base

    def primary_counterpart
      reload("primary_counterpart") if primary_counterpart_json.nil?
      return nil if primary_counterpart_json.empty?
      User.new(oauth_token, primary_counterpart_json)
    end

    def participants
      reload("participants") if participants_json.nil?
      return [] if participants_json.empty?
      participants = []
      participants_json.each do |participant|
        participants <<  User.new(oauth_token, participant)
      end
      participants
    end

    def creator
      reload("creator") if creator_json.nil?
      User.new(oauth_token, creator_json)
    end

    def save
      options = {"title" => self.title, "budgeted" => self.budgeted,
                  "description" => self.description, "archived" => self.archived}
      options.keys.each {|key| options["workspace[#{key}]"] = options.delete(key)}
      put_request("/workspaces/#{id}.json", options)
    end

    def reload(include_options="")
      include_options = include_options.delete(' ')
      include_options = "primary_counterpart,participants,creator" if include_options.eql? "all"
      options = {"include" => include_options} unless include_options.empty?
      response = get_request("/workspaces/#{self.id}.json", options)
      result = response["workspaces"].first[1]
      associated_hash =  {
          :primary_counterpart => ["users", "primary_counterpart_id"],
          :participants => ["users", "participant_ids"],
          :creator => ["users", "creator_id"]
      }
      associated_objects = parse_associated_objects(associated_hash, result, response)
      self.attributes = result
      self.associated_objects = associated_objects
    end

    def create_workspace_invitation(options)
      unless [:full_name, :email_address, :invitee_role].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end 
      unless ["buyer", "maven"].include? options[:invitee_role]
        raise InvalidParametersError.new("invitee_role must be 'buyer' or 'maven'")
      end
      options.keys.each {|key| options["invitation[#{key}]"] = options.delete(key)}
      post_request("/workspaces/#{id}/invite.json", options)
    end

  end

  class Expense < Base

    def save
      savable = [:notes, :category, :date, :amount_in_cents]
      options = {}
      savable.each do |inst|
        options["expense[#{inst}]"] = instance_variable_get("@#{inst.to_s}")
      end
      options["expense[billable]"] = instance_variable_get("@is_billable")
      put_request("/expenses/#{id}.json", options)
      true
    end

    def delete
      delete_request("/expenses/#{id}.json")
    end

    def reload(include_options="")
      response = get_request("/expenses/#{id}.json", {})
      result = response["expenses"][response["results"].first["id"]]
      self.attributes = result
    end
  end

  class TimeEntry < Base

    def delete
      delete_request("/time_entries/#{id}.json")
    end

    def save
      savable = ["date_performed", "time_in_minutes", "notes", "rate_in_cents", "billable"]
      options = {}
      savable.each do |inst|
        options["time_entry[#{inst}]"] = instance_variable_get("@#{inst}")
      end
      put_request("/time_entries/#{id}.json", options)
    end

    def user
      reload("user") if user_json.nil?
      return nil if user_json.empty?
      User.new(oauth_token, user_json)
    end

    def workspace
      reload("workspace") if workspace_json.nil?
      return nil if workspace_json.empty?
      Workspace.new(oauth_token, workspace_json)
    end

    def story
      reload("story") if story_json.nil?
      return nil if story_json.empty?
      Post.new(self.oauth_token, self.story_json)
    end

    def reload(include_options="")
      include_options = include_options.delete(' ')
      include_options = "user,story,workspace" if include_options.eql? "all"
      options = {"include" => include_options} unless include_options.empty?
      response = get_request("/time_entries/#{id}.json", options)
      result = response["time_entries"].first[1]
      associated_hash = {
          :user => ["users", "user_id"],
          :workspace => ["workspaces", "workspace_id"],
          :story => ["stories", "story_id"]
      }
      associated_objects = parse_associated_objects(associated_hash, result, response)
      self.attributes = result
      self.associated_objects = associated_objects
    end

  end

  class Invoice < Base
    def reload(include_options="")
      include_options = include_options.delete(' ')
      include_options = "time_entries,expenses,additional_items,workspaces,user" if include_options.eql? "all"
      options = {"include" => include_options} unless include_options.empty?
      response = get_request("/invoices/#{id}.json", options)
      result = response["invoices"].first[1]
      associated_hash = {
          :workspaces => ["workspaces", "workspace_ids"],
          :time_entries => ["time_entries", "time_entry_ids"],
          :expenses => ["expenses", "expense_ids"],
          :additional_items => ["additional_items", "additional_item_ids"]
      }
      associated_objects = parse_associated_objects(associated_hash, result, response)
      self.attributes = result
      self.associated_objects = associated_objects
    end

    def time_entries
      reload("time_entries") if time_entries_json.nil?
      return [] if time_entries_json.empty?
      time_entries = []
      time_entries_json.each do |entry|
        time_entries << TimeEntry.new(oauth_token, entry)
      end
      time_entries
    end

    def expenses
      reload("expenses") if expenses_json.nil?
      return [] if expenses_json.empty?
      expenses = []
      expenses_json.each do |expense|
        expenses << Expense.new(self.oauth_token, expense)
      end
      expenses
    end

    def additional_items
      reload("additional_items") if additional_items_json.nil?
      return [] if additional_items_json.empty?
      additional_items_json
    end

    def workspaces
      reload("workspaces") if workspaces_json.nil?
      return [] if workspaces_json.empty?
      workspaces = []
      workspaces_json.each do |workspace|
        workspaces << Workspace.new(oauth_token, workspace)
      end
      workspaces
    end

    def user
      reload("user") if user_json.nil?
      return nil if user_json.empty?
      User.new(oauth_token, user_json)
    end
  end

  class Story < Base
    def save
      savable = %w[title description story_type start_date due_date state budget_estimate_in_cents time_estimate_in_minutes percentage_complete]
      options = {}
      savable.each do |inst|
        options["story[#{inst}]"] = instance_variable_get("@#{inst}")  #attributes[inst]
      end
      put_request("/stories/#{id}.json", options)
    end

    def delete
      delete_request("/stories/#{id}.json")
    end

    def reload(include_options="")
      include_options = include_options.delete(' ')
      include_options = "workspace,assignees,parent,sub_stories,tags" if include_options.eql? "all"
      options = {"include" => include_options} unless include_options.empty?
      response = get_request("/stories/#{id}.json", options)
      result = response["stories"].first[1]
      associated_hash = {
          :workspace => ["workspaces", "workspace_id"],
          :parent_story => ["stories", "parent_id"],
          :assignees => ["users", "assignee_ids"],
          :sub_stories => ["stories", "sub_story_ids"]
      }
      associated_objects = parse_associated_objects(associated_hash, result, response)
      self.attributes = result
      self.associated_objects = associated_objects
    end

    def workspace
      reload if workspace_json.nil?
      return nil if workspace_json.empty?
      Workspace.new(oauth_token, workspace_json)
    end

    def parent_story
      reload if parent_story_json.nil?
      return nil if parent_story_json.empty?
      Story.new(oauth_token, parent_story_json)
    end

    def assignees
      reload if assignees_json.nil?
      return [] if assignees_json.empty?
      assignees_list = []
      self.assignees_json.each do |assg|
        assignees_list <<  User.new(self.oauth_token, assg)
      end
      assignees_list
    end

    def sub_stories
      reload if sub_stories_json.nil?
      return [] if sub_stories_json.empty?
      sub_stories = []
      sub_stories_json.each do |story|
        sub_stories << Story.new(oauth_token, story)
      end
      sub_stories
    end

    def tags
      reload if tags_json.nil?
      return [] if tags_json.empty?
      tags = []
      tags_json.each do |tag|
        tags << tag["name"]
      end
      tags
    end
  end

  class Post < Base
    def reload(include_options="")
      include_options = include_options.delete(' ')
      if include_options.eql? "all"
        include_options =  "subject,user,workspace,story,replies,newest_reply,newest_reply_user,recipients,google_documents,assets"
      end
      options = {"include" => include_options} unless include_options.empty?
      response = get_request("/posts/#{id}.json", options)
      result = response["posts"].first[1]
      associated_hash = {
          :subject => ["posts", "subject_id"],
          :user => ["users", "user_id"],
          :workspace => ["workspaces", "workspace_id"],
          :story => ["stories", "story_id"],
          :newest_reply => ["posts", "newest_reply_id"],
          :newest_reply_user => ["users", "newest_reply_user_id"],
          :recipients => ["users", "recipient_ids"],
          :assets => ["assets", "asset_ids"],
          :replies => ["posts", "reply_ids"],
          :google_documents => ["google_documents", "google_document_ids"]
      }
      associated_objects = parse_associated_objects(associated_hash, result, response)
      self.attributes = result
      self.associated_objects = associated_objects
    end

    def save
      savable = [ "message", "story_id"]
      options = {}
      savable.each do |inst|
        options["post[#{inst}]"] = instance_variable_get("@#{inst}")
      end
      put_request("/posts/#{self.id}.json", options)
    end

    def delete
      delete_request("/posts/#{self.id}.json")
    end

    def parent_post
      reload("subject") if subject_json.nil?
      return nil if subject_json.empty?
      Post.new(oauth_token, subject_json)
    end

    def user
      reload("user") if user_json.nil?
      return nil if user_json.empty?
      User.new(oauth_token, user_json)
    end

    def workspace
      reload("workspace") if workspace_json.nil?
      return [] if workspace_json.empty?
      Workspace.new(oauth_token, workspace_json)
    end

    def story
      reload("story") if story_json.nil?
      return nil if story_json.empty?
      Story.new(oauth_token, story_json)
    end

    def replies
      reload if replies_json.nil?
      return [] if replies_json.empty?
      replies = []
      replies_json.each do |post|
        replies << Post.new(oauth_token, post)
      end
      replies
    end

    def recipients
      reload("recipients") if recipients_json.nil?
      return [] if self.recipients_json.empty?
      recipients = []
      recipients_json.each do |user|
        recipients << User.new(oauth_token, user)
      end
      recipients
    end

    def newest_reply
      reload("newest_reply") if newest_reply_json.nil?
      return nil if newest_reply_json.empty?
      Post.new(oauth_token, newest_reply_json)
    end

    def newest_reply_user
      reload("newest_reply_user") if newest_reply_user_json.nil?
      return nil if newest_reply_user_json.empty?
      User.new(oauth_token, newest_reply_user_json)
    end

    def google_documents
      reload("google_documents") if google_documents_json.nil?
      return [] if google_documents_json.empty?
      google_doc_urls = []
      google_documents_json.each do |doc|
        google_doc_urls << doc["url"]
      end
      google_doc_urls
    end

    def assets
      reload("assets") if assets_json.nil?
      return [] if assets_json.empty?
      assets = []
      assets_json.each do |asset|
        assets << Asset.new(self.oauth_token, { "id" => asset["id"], "file_name" => asset["filename"]})
      end
      assets
    end
  end

end