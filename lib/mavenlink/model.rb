module Mavenlink
  
  class ExpenseCategory < Base
    attr_accessor :category
    def initialize(category)
      self.category = category
    end
  end

  class User < Base
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
    attr_accessor :oauth_token, :type, :data
    def initialize(oauth_token, type, data)
      self.oauth_token = oauth_token
      self.type = type
      self.data = data
    end

    def save
    end

    def delete
    end
  end

  class Workspace < Base
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
      return nil if self.primary_counterpart_json.empty?
      User.new(self.primary_counterpart_json["id"], self.primary_counterpart_json["full_name"], 
                self.primary_counterpart_json["photo_path"], 
                self.primary_counterpart_json["email_address"], self.primary_counterpart_json["headline"])
    end

    def participants
      self.reload if self.participants_json.nil?
      participants_list = []
      participants_json.each do |ptct|
        participants_list <<  User.new(ptct["id"], ptct["full_name"], ptct["photo_path"], 
                                       ptct["email_address"], ptct["headline"])
      end
      participants_list
    end

    def creator
      self.reload if self.creator_json.nil?
      User.new(self.creator_json["id"], self.creator_json["full_name"], self.creator_json["photo_path"], 
                self.creator_json["email_address"], self.creator_json["headline"])
    end

    def save
      options = {"title" => self.title, "budgeted" => self.budgeted,
                  "description" => self.description, "archived" => self.archived}
      options.keys.each {|key| options["workspace[#{key}]"] = options.delete(key)}
      response = put_request("/workspaces/#{self.id}.json", options)
    end

    def reload
      options = {"include" => "primary_counterpart,participants,creator"}
      response = get_request("/workspaces/#{self.id}.json", options)
      result = response["workspaces"].first[1]
      self.primary_counterpart_json = response["users"][result["primary_counterpart_id"]]
      self.participants_json = []
      result["participant_ids"].each {|k| self.participants_json << response["users"][k]}
      self.creator_json = response["users"][result["creator_id"]]
    end

    def create_workspace_invitation(options)
      unless ["full_name", "email_address", "invitee_role"].all? {|k| options.has_key? k}
        raise "Missing required parameters"
      end 
      unless ["buyer", "maven"].include? options["invitee_role"]
        raise "invitee_role must be 'buyer' or 'maven'"
      end
      options.keys.each {|key| options["invitation[#{key}]"] = options.delete(key)}
      response = post_request("/workspaces/#{self.id}/invite.json", options)
    end

  end

  class Expense < Base
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
      self.is_invoiced = is_invoiced
      self.is_billable = is_billable
      self.workspace_id = self.workspace_id
      self.user_id = user_id
      self.receipt_id = receipt_id
    end

    def save
      savable = ["notes", "category", "date", "amount_in_cents"]
      options = {}
      savable.each do |inst|
        options["expense[#{inst}]"] = instance_variable_get("@#{inst}")
      end
      # API returns is_billable but expects billable when updating
      options["expense[billable]"] = instance_variable_get("@is_billable")
      response = put_request("/expenses/#{self.id}.json", options)
    end

    def delete
      response = delete_request("/expenses/#{self.id}.json")
    end
  end

  class TimeEntry < Base
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
      response = delete_request("/time_entries/#{self.id}.json")
    end

    def save
      savable = ["date_performed", "story_id", "time_in_minutes", "notes",
                "rate_in_cents", "billable"]
      options = {}
      savable.each do |inst|
        options["time_entry[#{inst}]"] = instance_variable_get("@#{inst}")
      end
      response = put_request("/time_entries/#{self.id}.json", options)
    end

    def user
      self.reload if self.user_json.nil?
      User.new(self.user_json["id"], self.user_json["full_name"], self.user_json["photo_path"], 
                self.user_json["email_address"], self.user_json["headline"])
    end

    def workspace
      self.reload if self.workspace_json.nil?
    end

    def story
      self.reload if self.story_json.nil?
    end

    def reload
      options = {"include" => "user,story,workspace"}
      response = get_request("/time_entries/#{self.id}.json", options)
      result = response["time_entries"].first[1]
      self.user_json = response["users"][result["user_id"]]
      self.workspace_json = response["workspaces"][result["workspace_id"]]
      self.story_json = response["stories"][result["story_id"]]
    end

  end

  class Invoice < Base
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
      time_entries_json.each do |ent|
        time_entry_list << TimeEntry.new(self.oauth_token, ent["id"], ent["created_at"], ent["updated_at"], 
                                      ent["date_performed"], ent["story_id"], ent["time_in_minutes"],
                                      ent["billable"], ent["notes"], ent["rate_in_cents"], 
                                      ent["currency"], ent["currency_symbol"], ent["currency_base_unit"],
                                      ent["user_can_edit"], ent["workspace_id"], ent["user_id"], 
                                      nil, nil, nil)
      end
      time_entry_list
    end

    def expenses
      self.reload if self.expenses_json.nil?
    end

    def additional_items
      self.reload if self.additional_items_json.nil?
    end

    def workspaces
      self.reload if self.workspaces_json.nil?
    end  

    def user
      self.reload if self.user_json.nil?
      User.new(self.user_json["id"], self.user_json["full_name"], self.user_json["photo_path"], 
              self.user_json["email_address"], self.user_json["headline"])
    end
  end

  class Story < Base
    attr_accessor :oauth_token, :id, :title, :description, :updated_at, :created_at, :due_date, :start_date,
                  :story_type, :state, :position, :archived, :deleted_at, :sub_story_count, :budget_estimate_in_cents,
                  :time_estimate_in_minutes, :workspace_id, :parent_id, :workspace_json, :parent_story_json,
                  :assignees_json, :sub_stories_json, :tags_json, :percentage_complete
    def initialize(oauth_token, id, title, description, updated_at, created_at, due_date, start_date,
                  story_type, state, position, archived, deleted_at, sub_story_count, budget_estimate_in_cents,
                  time_estimate_in_minutes, workspace_id, parent_id, workspace_json, parent_story_json, 
                  assignees_json, sub_stories_json, tags_json, percentage_complete)
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
      savable = [ "title", "description", "parent_id", "story_type", "start_date", "due_date",
                  "state", "budget_estimate_in_cents", "time_estimate_in_minutes", "percentage_complete" ]
      options = {}
      savable.each do |inst|
        options["story[#{inst}]"] = instance_variable_get("@#{inst}")
      end
      response = put_request("/stories/#{self.id}.json", options)
    end

    def delete
      response = delete_request("/stories/#{self.id}.json")
    end

    def reload
      options = {"include" => "workspace,assignees,parent,sub_stories,tags"}
      response = get_request("/stories/#{self.id}.json", options)
      self.workspace_json, self.parent_story_json = [], [] 
      self.sub_stories_json, self.assignees_json = [], []
      result = response["stories"].first[1]
      result["assignee_ids"].each {|k| self.assignees_json << response["users"][k]} unless result["assignee_ids"].nil?
      result["sub_story_ids"].each {|k| self.sub_stories_json << response["stories"][k]} unless result["sub_story_ids"].nil?
      self.parent_story_json = response["users"][result["parent_id"]]
      self.workspace_json = response["workspaces"][result["workspace_id"]]
    end

    def workspace
      self.reload if self.workspace_json.nil?
      wksp = self.workspace_json
      Workspace.new(self.oauth_token, wksp["id"], wksp["title"], wksp["archived"], 
                    wksp["description"], wksp["effective_due_date"], wksp["budgeted"], 
                    wksp["change_orders_enabled"], wksp["updated_at"], wksp["created_at"], 
                    wksp["consultant_role_name"], wksp["client_role_name"], 
                    wksp["can_create_line_items"], wksp["default_rate"], 
                    wksp["currency_symbol"], wksp["currency_base_unit"], 
                    wksp["can_invite"], wksp["has_budget_access"], wksp["price"], 
                    wksp["price_in_cent"], wksp["budget_used"], wksp["over_budget"], wksp["currency"], nil, nil, nil)
    end

    def parent_story
      self.reload if self.parent_story_json.nil?
      return nil if self.parent_story_json.empty?
      stry = self.parent_story_json
      Story.new(self.oauth_token, stry["id"], stry["title"], stry["description"], stry["updated_at"], 
                stry["created_at"], stry["due_date"], stry["start_date"], stry["story_type"], 
                stry["state"], stry["position"], stry["archived"], stry["deleted_at"], 
                stry["sub_story_count"], stry["budget_estimate_in_cents"], 
                stry["time_estimate_in_minutes"], stry["workspace_id"], stry["parent_id"], 
                self.workspace_json, nil, nil, nil, nil, stry["percentage_complete"])
    end

    def assignees
      self.reload if self.assignees_json.nil?
      return nil if self.assignees_json.empty?
      assignees_list = []
      self.assignees_json.each do |assg|
        assignees_list <<  User.new(assg["id"], assg["full_name"], assg["photo_path"], 
                                    assg["email_address"], assg["headline"])
      end
      assignees_list
    end

    def sub_stories
      self.reload if self.sub_stories_json.nil?
      return nil if self.sub_stories_json.empty?
      sub_stories_list = []
      self.sub_stories_json.each do |stry|
        sub_stories_list << Story.new(self.oauth_token, stry["id"], stry["title"], stry["description"], 
                                      stry["updated_at"], stry["created_at"], stry["due_date"], stry["start_date"], 
                                      stry["story_type"], stry["state"], stry["position"], stry["archived"], 
                                      stry["deleted_at"], stry["sub_story_count"], stry["budget_estimate_in_cents"], 
                                      stry["time_estimate_in_cents"], stry["workspace_id"], stry["parent_id"], 
                                      self.workspace_json, nil, nil, nil, nil, stry["percentage_complete"])
      end
      sub_stories_list
    end

    def tags
      self.reload if self.tags_json.nil?
      return nil if self.tags_json.empty?
      tags_list = []
      self.tags_json.each do |tag|
        tags_list << tag["name"]
      end
      tags_list
    end
  end

end