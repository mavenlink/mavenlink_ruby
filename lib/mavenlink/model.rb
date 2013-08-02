require_relative 'helper'

module Mavenlink

  class User < Base
    include Mavenlink::Helper
    attr_accessor :user_id, :full_name, :photo_path, :email_address, :headline
    def initialize(user_id, full_name, photo_path, email_address, headline)
      self.user_id = user_id
      self.full_name = full_name
      self.photo_path = photo_path
      self.email_address = email_address
      self.headline = headline
    end
  end

  class Asset < Base
    include Mavenlink::Helper
    
    attr_accessor :oauth_token, :id, :file_name
    def initialize(oauth_token, id, file_name)
      self.oauth_token = oauth_token
      self.id = id
      self.file_name = file_name
    end

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
    include Mavenlink::Helper

    attr_accessor :oauth_token, :id, :title, :archived, :description, :effective_due_date,
                  :budgeted, :change_orders_enabled, :updated_at, :created_at, :consultant_role_name,
                  :client_role_name, :can_create_line_items, :default_rate, :currency_symbol, 
                  :currency_base_unit, :can_invite, :has_budget_access, :price, :price_in_cent,
                  :budget_used, :over_budget, :currency, :primary_counterpart_json,
                  :participants_json, :creator_json
    def initialize(oauth_token, id, title, archived, description, effective_due_date,
                  budgeted, change_orders_enabled, updated_at, created_at, consultant_role_name,
                  client_role_name, can_create_line_items, default_rate, currency_symbol, 
                  currency_base_unit, can_invite, has_budget_access, price, price_in_cent,
                  budget_used, over_budget, currency, primary_counterpart_json, participants_json,
                  creator_json)
      self.oauth_token = oauth_token
      self.id = id
      self.title = title
      self.archived = archived
      self.description = description,
      self.effective_due_date = effective_due_date
      self.budgeted = budgeted
      self.change_orders_enabled = change_orders_enabled
      self.updated_at = updated_at
      self.created_at = created_at
      self.consultant_role_name = consultant_role_name
      self.client_role_name = client_role_name
      self.can_create_line_items = can_create_line_items
      self.default_rate = default_rate
      self.currency_symbol = currency_symbol
      self.currency_base_unit = currency_base_unit
      self.can_invite = can_invite
      self.has_budget_access = has_budget_access
      self.price = price
      self.price_in_cent = price_in_cent
      self.budget_used = budget_used
      self.over_budget = over_budget
      self.currency = currency
      self.primary_counterpart_json = primary_counterpart_json
      self.participants_json = participants_json
      self.creator_json = creator_json
    end

    def primary_counterpart
      self.reload if self.primary_counterpart_json.nil?
      return nil if self.primary_counterpart_json.nil? || self.primary_counterpart_json.empty?
      parse_user(self.primary_counterpart_json)
    end

    def participants
      self.reload if self.participants_json.nil?
      participants_list = []
      participants_json.each do |ptct|
        participants_list <<  parse_user(ptct)
      end
      participants_list
    end

    def creator
      self.reload if self.creator_json.nil?
      parse_user(self.creator_json)
    end

    def save
      options = {"title" => self.title, "budgeted" => self.budgeted,
                  "description" => self.description, "archived" => self.archived}
      options.keys.each {|key| options["workspace[#{key}]"] = options.delete(key)}
      put_request("/workspaces/#{self.id}.json", options)
    end

    def reload
      options = {"include" => "primary_counterpart,participants,creator"}
      response = get_request("/workspaces/#{self.id}.json", options)
      result = response["workspaces"].first[1]
      self.primary_counterpart_json = response["users"][result["primary_counterpart_id"]]
      self.participants_json = []
      result["participant_ids"].each {|k| self.participants_json << response["users"][k]}
      self.creator_json = response["users"][result["creator_id"]]
      self.instance_variables.each do |var|
        key = var.to_s.gsub("@", "")
        instance_variable_set(var, result[key]) if result.has_key? key
      end
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
    include Mavenlink::Helper

    attr_accessor :oauth_token, :id, :created_at, :updated_at, :date, :notes, :category, :amount_in_cents, :currency,
                  :currency_symbol, :currency_base_unit, :user_can_edit, :is_invoiced, :is_billable, 
                  :workspace_id, :user_id, :receipt_id
    def initialize(oauth_token, id, created_at, updated_at, date, notes, category, amount_in_cents, currency,
                  currency_symbol, currency_base_unit, user_can_edit, is_invoiced, is_billable, 
                  workspace_id, user_id, receipt_id)
      self.oauth_token = oauth_token
      self.id = id
      self.created_at = created_at
      self.updated_at = updated_at
      self.date = date
      self.notes = notes
      self.category = category
      self.amount_in_cents = amount_in_cents
      self.currency = currency
      self.currency_symbol = currency_symbol
      self.currency_base_unit = currency_base_unit
      self.user_can_edit = user_can_edit
      self.workspace_id = workspace_id
      self.is_invoiced = is_invoiced
      self.is_billable = is_billable
      self.workspace_id = workspace_id
      self.user_id = user_id
      self.receipt_id = receipt_id
    end

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

    def reload
      response = get_request("/expenses/#{self.id}.json", {})
      result = response["expenses"][response["results"].first["id"]]
      self.instance_variables.each do |var|
        key = var.to_s.gsub("@", "")
        instance_variable_set(var, result[key]) if result.has_key? key
      end
    end
  end

  class TimeEntry < Base
    include Mavenlink::Helper

    attr_accessor :oauth_token, :id, :created_at, :updated_at, :date_performed, :story_id, :time_in_minutes,
                  :billable, :notes, :rate_in_cents, :currency, :currency_symbol, :currency_base_unit,
                  :user_can_edit, :workspace_id, :user_id, :user_json, :workspace_json, :story_json

    def initialize(oauth_token, id, created_at, updated_at, date_performed, story_id, time_in_minutes,
                  billable, notes, rate_in_cents, currency, currency_symbol, currency_base_unit,
                  user_can_edit, workspace_id, user_id, user_json, workspace_json, story_json)
      self.oauth_token = oauth_token
      self.id = id
      self.created_at = created_at
      self.updated_at = updated_at
      self.date_performed = date_performed
      self.story_id = story_id
      self.time_in_minutes = time_in_minutes
      self.billable = billable
      self.notes = notes
      self.rate_in_cents = rate_in_cents
      self.currency = currency
      self.currency_symbol = currency_symbol
      self.currency_base_unit = currency_base_unit
      self.user_can_edit = user_can_edit
      self.workspace_id = workspace_id
      self.user_id = user_id
      self.user_json = user_json
      self.workspace_json = workspace_json
      self.story_json = story_json
    end

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
      self.reload if self.user_json.nil?
      parse_user(self.user_json)
    end

    def workspace
      self.reload if self.workspace_json.nil?
      parse_workspace(self.oauth_token, self.workspace_json)
    end

    def story
      self.reload if self.story_json.nil?
      return nil if self.story_id.nil?
      parse_post(self.oauth_token, self.story_json)
    end

    def reload
      options = {"include" => "user,story,workspace"}
      response = get_request("/time_entries/#{self.id}.json", options)
      result = response["time_entries"].first[1]
      self.user_json = response["users"][result["user_id"]]
      self.workspace_json = response["workspaces"][result["workspace_id"]]
      self.story_json = response["stories"][result["story_id"]]

      self.instance_variables.each do |var|
        key = var.to_s.gsub("@", "")
        instance_variable_set(var, result[key]) if result.has_key? key
      end
    end

  end

  class Invoice < Base
    include Mavenlink::Helper

    attr_accessor :oauth_token, :id, :created_at, :updated_at, :invoice_date, :due_date, :message, 
                  :draft, :status, :balance_in_cents, :currency, :currency_base_unit, :currency_symbol,
                  :payment_schedule, :workspace_ids, :user_id, :recipient_id, :user_json,
                  :time_entries_json, :expenses_json, :additional_items_json, :workspaces_json 
                  
    def initialize(oauth_token, id, created_at, updated_at, invoice_date, due_date, message, 
                  draft, status, balance_in_cents, currency, currency_base_unit, currency_symbol,
                  payment_schedule, workspace_ids, user_id, recipient_id, time_entries_json,
                  expenses_json, additional_items_json, workspaces_json, user_json)
      self.oauth_token = oauth_token
      self.id = id
      self.created_at = created_at
      self.updated_at = updated_at
      self.invoice_date = invoice_date
      self.due_date = due_date
			self.message = message
      self.draft = draft
      self.status = status
      self.balance_in_cents = balance_in_cents
      self.currency = currency
      self.currency_base_unit = currency_base_unit
      self.currency_symbol = currency_symbol
      self.payment_schedule = payment_schedule
    	self.workspace_ids = workspace_ids
    	self.user_id = user_id
    	self.recipient_id = recipient_id
      self.time_entries_json = time_entries_json
      self.expenses_json = expenses_json
      self.additional_items_json = additional_items_json
      self.workspaces_json = workspaces_json
      self.user_json = user_json
    end

    def reload
      options = {"include" => "time_entries,expenses,additional_items,workspaces,user"}
      response = get_request("/invoices/#{self.id}.json", options)
      result = response["invoices"].first[1]
      self.instance_variables.each do |var|
        key = var.to_s.gsub("@", "")
        instance_variable_set(var, result[key]) if result.has_key? key
      end

      self.time_entries_json, self.expenses_json = [], [] 
      self.additional_items_json, self.workspaces_json = [], []
      result = response["invoices"].first[1]
      result["time_entry_ids"].each {|k| self.time_entries_json << response["time_entries"][k]}
      result["additional_item_ids"].each{|k| self.additional_items_json << response["additional_items"][k]}
      result["expense_ids"].each{|k| self.expenses_json << response["expenses"][k]}
      result["workspace_ids"].each{|k| self.workspaces_json << response["workspaces"][k]}
      self.user_json = response["users"][result["user_id"]]
    end

    def time_entries
      self.reload if self.time_entries_json.nil?
      time_entry_list = []
      self.time_entries_json.each do |ent|
        time_entry_list << parse_time_entry(self.oauth_token, ent)
      end
      time_entry_list
    end

    def expenses
      self.reload if self.expenses_json.nil?
      expenses = []
      self.expenses_json.each do |exp|
        expenses << parse_expense(self.oauth_token, exp)
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
        workspaces << parse_workspace(self.oauth_token, wks)
      end
      workspaces
    end

    def user
      self.reload if self.user_json.nil?
      parse_user(self.user_json)
    end
  end

  class Story < Base
    include Mavenlink::Helper

    attr_accessor :oauth_token, :id, :title, :description, :updated_at, :created_at, :due_date, :start_date,
                  :story_type, :state, :position, :archived, :deleted_at, :sub_story_count, :budget_estimate_in_cents,
                  :time_estimate_in_minutes, :workspace_id, :parent_id, :workspace_json, :parent_story_json,
                  :assignees_json, :sub_stories_json, :tags_json, :percentage_complete
    def initialize(oauth_token, id, title, description, updated_at, created_at, due_date, start_date,
                  story_type, state, position, archived, deleted_at, sub_story_count, budget_estimate_in_cents,
                  time_estimate_in_minutes, workspace_id, parent_id, percentage_complete, workspace_json, parent_story_json,
                  assignees_json, sub_stories_json, tags_json)
      self.oauth_token = oauth_token
      self.id = id
      self.title = title
      self.description = description
      self.updated_at = updated_at
      self.created_at = created_at
      self.due_date = due_date
      self.start_date = start_date
      self.story_type = story_type
      self.state = state
      self.position = position
      self.archived = archived
      self.deleted_at = deleted_at
      self.sub_story_count = sub_story_count
      self.budget_estimate_in_cents = budget_estimate_in_cents
      self.time_estimate_in_minutes = time_estimate_in_minutes
      self.workspace_id = workspace_id
      self.parent_id = parent_id
      self.workspace_json = workspace_json
      self.parent_story_json = parent_story_json
      self.assignees_json = assignees_json
      self.tags_json = tags_json
      self.sub_stories_json = sub_stories_json
      self.percentage_complete = percentage_complete
    end

    def save
      savable = [ "title", "description", "story_type", "start_date", "due_date",
                  "state", "budget_estimate_in_cents", "time_estimate_in_minutes", "percentage_complete" ]
      options = {}
      savable.each do |inst|
        options["story[#{inst}]"] = instance_variable_get("@#{inst}")
      end
      put_request("/stories/#{self.id}.json", options)
    end

    def delete
      delete_request("/stories/#{self.id}.json")
    end

    def reload
      options = {"include" => "workspace,assignees,parent,sub_stories,tags"}
      response = get_request("/stories/#{self.id}.json", options)
      result = response["stories"].first[1]
      self.instance_variables.each do |var|
        key = var.to_s.gsub("@", "")
        instance_variable_set(var, result[key]) if result.has_key? key
      end

      self.workspace_json, self.parent_story_json = [], [] 
      self.sub_stories_json, self.assignees_json = [], []
      result = response["stories"].first[1]
      result["assignee_ids"].each {|k| self.assignees_json << response["users"][k]} unless result["assignee_ids"].nil?
      result["sub_story_ids"].each {|k| self.sub_stories_json << response["stories"][k]} unless result["sub_story_ids"].nil?
      self.parent_story_json = response["users"][result["parent_id"]]
      self.workspace_json = response["workspaces"][result["workspace_id"]]
    end

    def workspace
      self.reload if self.workspace_json.nil? or workspace_json.empty?
      parse_workspace(self.oauth_token, self.workspace_json)
    end

    def parent_story
      self.reload if self.parent_story_json.nil?
      return nil if self.parent_story_json.nil?
      parse_story(self.oauth_token, self.parent_story_json)
    end

    def assignees
      self.reload if self.assignees_json.nil?
      return [] if self.assignees_json.empty?
      assignees_list = []
      self.assignees_json.each do |assg|
        assignees_list <<  parse_user(assg)
      end
      assignees_list
    end

    def sub_stories
      self.reload if self.sub_stories_json.nil?
      return [] if self.sub_stories_json.empty?
      sub_stories_list = []
      self.sub_stories_json.each do |stry|
        sub_stories_list << parse_story(self.oauth_token, stry)
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
    include Mavenlink::Helper

    attr_accessor :oauth_token, :id, :newest_reply_at, :message, :has_attachment, :created_at, :updated_at, :reply_count,
                  :private_val, :user_id, :workspace_id, :workspace_type, :reply, :subject_id, :subject_type, :story_id,
                  :subject_json, :user_json, :workspace_json, :story_json, :replies_json, :newest_reply_json, 
                  :newest_reply_user_json, :recipients_json, :google_documents_json, :assets_json
    def initialize(oauth_token, id, newest_reply_at, message, has_attachment, created_at, updated_at, reply_count,
                  private_val, user_id, workspace_id, workspace_type, reply, subject_id, subject_type, story_id,
                  subject_json, user_json, workspace_json, story_json, replies_json, newest_reply_json, 
                  newest_reply_user_json, recipients_json, google_documents_json, assets_json)
      self.oauth_token = oauth_token
      self.id = id
      self.newest_reply_at = newest_reply_at
      self.message = message
      self.has_attachment = has_attachment
      self.created_at = created_at
      self.updated_at = updated_at
      self.reply_count = reply_count
      self.private_val = private_val
      self.user_id = user_id
      self.workspace_id = workspace_id
      self.workspace_type = workspace_type
      self.reply = reply
      self.subject_id = subject_id
      self.subject_type = subject_type
      self.story_id = story_id
      self.subject_json = subject_json
      self.user_json = user_json
      self.workspace_json = workspace_json
      self.story_json = story_json
      self.replies_json = replies_json
      self.newest_reply_json = newest_reply_json
      self.newest_reply_user_json = newest_reply_user_json
      self.recipients_json = recipients_json
      self.google_documents_json = google_documents_json
      self.assets_json = assets_json
    end

    def reload
      options = {"include" => "subject,user,workspace,story,replies,newest_reply,newest_reply_user,recipients,google_documents,assets"}
      response = get_request("/posts/#{self.id}.json", options)
      result = response["posts"].first[1]

      self.instance_variables.each do |var|
        key = var.to_s.gsub("@", "")
        instance_variable_set(var, result[key]) if result.has_key? key
      end

      self.subject_json = response["posts"][result["subject_id"]] unless result["subject_id"].nil?
      self.user_json = response["users"][result["user_id"]]
      self.workspace_json = response["workspaces"][result["workspace_id"]]
      self.story_json = response["stories"][result["story_id"]] unless result["story_id"].nil?
      self.newest_reply_json = response["posts"][result["newest_reply_id"]] unless result["newest_reply_id"].nil?
      self.newest_reply_user_json = result["users"][response["newest_reply_user_id"]] unless result["newest_reply_user_id"].nil?
      self.recipients_json, self.google_documents_json = [], []
      self.assets_json, self.replies_json = [], []
      result["recipient_ids"].each {|k| self.recipients_json << response["users"][k]} unless result["recipient_ids"].nil?
      self.google_documents_json = google_documents
      result["asset_ids"].each {|k| self.assets_json << response["assets"][k]} unless result["reply_ids"].nil?
      result["reply_ids"].each {|k| self.replies_json << response["posts"][k]} unless result["reply_ids"].nil?
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
      parse_post(self.oauth_token, self.subject_json)
    end

    def user
      self.reload if self.user_json.nil?
      parse_user(self.user_json)
    end

    def workspace
      self.reload if self.workspace_json.nil?
      parse_workspace(self.oauth_token, self.workspace_json)
    end

    def story
      self.reload if self.story_json.nil?
      return nil if self.story_json.nil?
      parse_story(self.oauth_token, self.story_json)
    end

    def replies
      self.reload if self.replies_json.nil?
      return [] if self.replies_json.nil?
      replies = []
      self.replies_json.each do |pst|
        replies << parse_post(self.oauth_token, pst)
      end
      replies
    end

    def recipients
      self.reload if self.recipients_json.nil?
      return [] if self.recipients_json.nil?
      recipients = []
      self.recipients_json.each do |usr|
        recipients << parse_user(usr)
      end
      recipients
    end

    def newest_reply
      self.reload if self.newest_reply_json.nil?
      return nil if self.newest_reply_json.nil?
      parse_post(self.oauth_token, self.newest_reply_json)
    end

    def newest_reply_user
      self.reload if self.newest_reply_user_json.nil?
      return nil if self.newest_reply_user_json.nil?
      parse_user(self.newest_reply_user_json)
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
        assets << Asset.new(self.oauth_token, asset["id"], asset["filename"])
      end
      assets
    end
  end

end