module Mavenlink

  class User < Base
  end

  class Asset < Base

    def save
      options = {}
      options["asset[filename]"] = self.file_name
      put_request("/assets/#{self.id}.json", options)
    end

    def delete
      delete_request("/assets/#{self.id}.json")
    end
  end

  class Workspace < Base

    def primary_counterpart
      reload("primary_counterpart") if primary_counterpart_json.nil? # <-- there should really be a distinction between not having asked, and having asked and determined that no primary_counterpart exists.
      return nil if primary_counterpart_json.nil? || primary_counterpart_json.empty?
      User.new(oauth_token, primary_counterpart_json)
    end

    def participants
      reload("participants") if participants_json.nil?
      participants_list = []
      participants_json.each do |ptct|
        participants_list <<  User.new(oauth_token, ptct)
      end
      participants_list
    end

    def creator
      reload("creator") if creator_json.nil?
      User.new(oauth_token, creator_json)
    end

    def save
      options = {"title" => self.title, "budgeted" => self.budgeted,
                  "description" => self.description, "archived" => self.archived}
      options.keys.each {|key| options["workspace[#{key}]"] = options.delete(key)}
      put_request("/workspaces/#{self.id}.json", options)
    end

    def reload(include_opt="")
      include_opt = include_opt.delete(' ')
      include_opt = "primary_counterpart,participants,creator" if include_opt.eql? "all"
      options = {"include" => include_opt} unless include_opt.empty?
      response = get_request("/workspaces/#{self.id}.json", options)
      result = response["workspaces"].first[1]
      assoc_hash =  {
          :primary_counterpart => ["users", "primary_counterpart_id"],
          :participants => ["users", "participant_ids"],
          :creator => ["users", "creator_id"]
      }
      wksp_opts = parse_associated_objects(assoc_hash, result, response)
      self.attributes = result
      self.associated_objects = wksp_opts
    end

    def create_workspace_invitation(options)
      unless [:full_name, :email_address, :invitee_role].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end 
      unless ["buyer", "maven"].include? options[:invitee_role]
        raise InvalidParametersError.new("invitee_role must be 'buyer' or 'maven'")
      end
      options.keys.each {|key| options["invitation[#{key}]"] = options.delete(key)}
      post_request("/workspaces/#{self.id}/invite.json", options)
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
      put_request("/expenses/#{self.id}.json", options)
      true
    end

    def delete
      delete_request("/expenses/#{self.id}.json")
    end

    def reload(include_opt="")
      response = get_request("/expenses/#{self.id}.json", {})
      result = response["expenses"][response["results"].first["id"]]
      self.attributes = result
    end
  end

  class TimeEntry < Base

    def delete
      delete_request("/time_entries/#{self.id}.json")
    end

    def save
      savable = ["date_performed", "time_in_minutes", "notes", "rate_in_cents", "billable"]
      options = {}
      savable.each do |inst|
        options["time_entry[#{inst}]"] = instance_variable_get("@#{inst}")
      end
      put_request("/time_entries/#{self.id}.json", options)
    end

    def user
      reload("user") if user_json.nil?
      User.new(oauth_token, user_json)
    end

    def workspace
      self.reload("workspace") if self.workspace_json.nil?
      Workspace.new(self.oauth_token, self.workspace_json)
    end

    def story
      self.reload("story") if self.story_json.nil?
      return nil if self.story_id.nil?
      Post.new(self.oauth_token, self.story_json)
    end

    def reload(include_opt="")
      include_opt = include_opt.delete(' ')
      include_opt = "user,story,workspace" if include_opt.eql? "all"
      options = {"include" => include_opt} unless include_opt.empty?

      response = get_request("/time_entries/#{self.id}.json", options)
      result = response["time_entries"].first[1]
      assoc_hash = {
          :user => ["users", "user_id"],
          :workspace => ["workspaces", "workspace_id"],
          :story => ["stories", "story_id"]
      }
      ent_opts = parse_associated_objects(assoc_hash, result, response)
      self.attributes = result
      self.associated_objects = ent_opts
    end

  end

  class Invoice < Base
    def reload(include_opt="")
      include_opt = include_opt.delete(' ')
      include_opt = "time_entries,expenses,additional_items,workspaces,user" if include_opt.eql? "all"
      options = {"include" => include_opt} unless include_opt.empty?
      response = get_request("/invoices/#{self.id}.json", options)
      result = response["invoices"].first[1]
      assoc_hash = {
          :workspaces => ["workspaces", "workspace_ids"],
          :time_entries => ["time_entries", "time_entry_ids"],
          :expenses => ["expenses", "expense_ids"],
          :additional_items => ["additional_items", "additional_item_ids"]
      }
      inv_opts = parse_associated_objects(assoc_hash, result, response)
      self.attributes = result
      self.associated_objects = inv_opts
    end

    def time_entries
      self.reload if self.time_entries_json.nil?
      time_entry_list = []
      self.time_entries_json.each do |ent|
        time_entry_list << TimeEntry.new(self.oauth_token, ent)
      end
      time_entry_list
    end

    def expenses
      self.reload if self.expenses_json.nil?
      expenses = []
      self.expenses_json.each do |exp|
        expenses << Expense.new(self.oauth_token, exp)
      end
      expenses
    end

    def additional_items
      self.reload if self.additional_items_json.nil?
      self.additional_items_json
    end

    def workspaces
      self.reload if self.workspaces_json.nil?
      workspaces = []
      self.workspaces_json.each do |wks|
        workspaces << Workspace.new(self.oauth_token, wks)
      end
      workspaces
    end

    def user
      self.reload if self.user_json.nil?
      User.new(self.oauth_token, self.user_json)
    end
  end

  class Story < Base
    def save
      savable = %w[title description story_type start_date due_date state budget_estimate_in_cents time_estimate_in_minutes percentage_complete]
      options = {}
      savable.each do |inst|
        options["story[#{inst}]"] = attributes[inst] #instance_variable_get("@#{inst}")
      end
      put_request("/stories/#{id}.json", options)
    end

    def delete
      delete_request("/stories/#{id}.json")
    end

    def reload(include_opt="")
      include_opt = include_opt.delete(' ')
      include_opt = "workspace,assignees,parent,sub_stories,tags" if include_opt.eql? "all"
      options = {"include" => include_opt} unless include_opt.empty?
      response = get_request("/stories/#{self.id}.json", options)
      result = response["stories"].first[1]
      assoc_hash = {
          :workspace => ["workspaces", "workspace_id"],
          :parent_story => ["stories", "parent_id"],
          :assignees => ["users", "assignee_ids"],
          :sub_stories => ["stories", "sub_story_ids"]
      }
      stry_opts = parse_associated_objects(assoc_hash, result, response)
      self.attributes = result
      self.associated_objects = stry_opts
    end

    def workspace
      self.reload if self.workspace_json.nil? or workspace_json.empty?
      Workspace.new(self.oauth_token, self.workspace_json)
    end

    def parent_story
      self.reload if self.parent_story_json.nil?
      return nil if self.parent_story_json.nil?
      Story.new(self.oauth_token, self.parent_story_json)
    end

    def assignees
      self.reload if self.assignees_json.nil?
      return [] if self.assignees_json.empty?
      assignees_list = []
      self.assignees_json.each do |assg|
        assignees_list <<  User.new(self.oauth_token, assg)
      end
      assignees_list
    end

    def sub_stories
      self.reload if self.sub_stories_json.nil?
      return [] if self.sub_stories_json.empty?
      sub_stories_list = []
      self.sub_stories_json.each do |stry|
        sub_stories_list << Story.new(self.oauth_token, stry)
      end
      sub_stories_list
    end

    def tags
      self.reload if self.tags_json.nil?
      return [] if self.tags_json.empty?
      tags_list = []
      self.tags_json.each do |tag|
        tags_list << tag["name"]
      end
      tags_list
    end
  end

  class Post < Base
    def reload(include_opt="")
      include_opt = include_opt.delete(' ')
      if include_opt.eql? "all"
        include_opt =  "subject,user,workspace,story,replies,newest_reply,newest_reply_user,recipients,google_documents,assets"
      end
      options = {"include" => include_opt} unless include_opt.empty?
      response = get_request("/posts/#{self.id}.json", options)
      result = response["posts"].first[1]
      assoc_hash = {
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
      pst_opts = parse_associated_objects(assoc_hash, result, response)
      self.attributes = result
      self.associated_objects = pst_opts
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
      self.reload if self.subject_json.nil?
      return nil if self.subject_json.nil?
      Post.new(self.oauth_token, self.subject_json)
    end

    def user
      self.reload if self.user_json.nil?
      User.new(self.oauth_token, self.user_json)
    end

    def workspace
      self.reload if self.workspace_json.nil?
      Workspace.new(self.oauth_token, self.workspace_json)
    end

    def story
      self.reload if self.story_json.nil?
      return nil if self.story_json.nil?
      Story.new(self.oauth_token, self.story_json)
    end

    def replies
      self.reload if self.replies_json.nil?
      return [] if self.replies_json.nil?
      replies = []
      self.replies_json.each do |pst|
        replies << Post.new(self.oauth_token, pst)
      end
      replies
    end

    def recipients
      self.reload if self.recipients_json.nil?
      return [] if self.recipients_json.nil?
      recipients = []
      self.recipients_json.each do |usr|
        recipients << User.new(self.oauth_token, usr)
      end
      recipients
    end

    def newest_reply
      self.reload if self.newest_reply_json.nil?
      return nil if self.newest_reply_json.nil?
      Post.new(self.oauth_token, self.newest_reply_json)
    end

    def newest_reply_user
      self.reload if self.newest_reply_user_json.nil?
      return nil if self.newest_reply_user_json.nil?
      User.new(self.oauth_token, self.newest_reply_user_json)
    end

    def google_documents
      self.reload if self.google_documents_json.nil?
      return [] if self.google_documents_json.empty? || self.google_documents_json.nil?
      google_doc_urls = []
      self.google_documents_json.each do |doc|
        google_doc_urls << doc["url"]
      end
      google_doc_urls
    end

    def assets
      self.reload if self.assets_json.nil?
      return [] if self.assets_json.nil? || self.assets_json.empty?
      assets = []
      self.assets_json.each do |asset|
        assets << Asset.new(self.oauth_token, { "id" => asset["id"], "file_name" => asset["filename"]})
      end
      assets
    end
  end

end