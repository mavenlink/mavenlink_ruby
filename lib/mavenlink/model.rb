module Mavenlink
  
  class ExpenseCategory < Base
    attr_accessor :category
    def initialize(category)
      self.category = category
    end
  end

  class User < Base
    attr_accessor :oauth_token, :user_id, :full_name, :photo_path, :email_address, :headline
    def initialize(user_id, full_name, photo_path, email_address, headline)
      self.user_id = user_id
      self.full_name = full_name
      self.photo_path = photo_path
      self.email_address = email_address
      self.headline = headline
    end
  end

  class Expense < Base
    attr_accessor :oauth_token, :id, :created_at, :updated_at, :date, :notes, :category, :amount_in_cents, :currency,
                  :currency_symbol, :currency_base_unit, :user_can_edit, :is_invoiced, :is_billable, 
                  :workspace_id, :user_id, :receipt_id
    def initialize(id, created_at, updated_at, date, notes, category, amount_in_cents, currency,
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
  end

  class TimeEntry < Base
    attr_accessor :oauth_token, :id, :created_at, :updated_at, :date_performed, :story_id, :time_in_minutes,
                  :billable, :notes, :rate_in_cents, :currency, :currency_symbol, :currency_base_unit,
                  :user_can_edit, :workspace_id, :user_id, :user_json, :workspace_json, :story_json, :options_hash

    def initialize(oauth_token, id, created_at, updated_at, date_performed, story_id, time_in_minutes,
                  billable, notes, rate_in_cents, currency, currency_symbol, currency_base_unit,
                  user_can_edit, workspace_id, user_id, user_json, workspace_json, story_json, options_hash)
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
      self.options_hash = options_hash
    end

    def delete
      response = delete_request("/time_entries/#{self.id}.json")
    end

    def save(options)
      options.keys.each {|key| options["time_entry[#{key}]"] = options.delete(key)}
      # REmove first "time_entries.json/#{time_entry_id}"
      response = put_request("/time_entries/#{self.id}.json", options)
    end

    # Why does a time entry have multiple users? 
    def users
      users = []
      self.user_json.each do |key, user|
        users << User.new(user["id"], user["full_name"], user["photo_path"], 
        user["email_address"], user["headline"])
      end
      users
    end

    def workspace
    end

    def story
    end

    def reload
      response = get_request("/time_entries.json", self.options_hash)
      self.user_json = response["users"]
      self.story_json = response["stories"]
      self.workspace_json = response["workspaces"]
    end

  end

end