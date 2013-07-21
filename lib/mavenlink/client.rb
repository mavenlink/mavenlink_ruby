module Mavenlink
  class Client < Base

    def initialize(oauth_token)
      super(oauth_token)
    end

    def users(options = {})
      response = get_request("/users.json", options)
      user_data = response["users"]
      results = response["results"]
      users = []
      results.each do |result|
        if result["key"].eql? "users"
          user = user_data[result["id"]]
          users << User.new(user["id"], user["full_name"], user["photo_path"], 
                  user["email_address"], user["headline"])
        end
      end
      users
    end

    def expense_categories
      expense_categories = get_request("/expense_categories.json")
      categories = []
      expense_categories.each do |category|
        categories << ExpenseCategory.new(category)
      end
      categories
    end

    def expenses(options = {})
      response = get_request("/expenses.json", options)
      results = response["results"]
      expenses_data = response["expenses"]
      expenses = []
      results.each do |result|
        if result["key"].eql? "expenses"
          exp = expenses_data[result["id"]]
          expenses << Expense.new(exp["id"], exp["created_at"], exp["updated_at"], exp["date"], 
                      exp["notes"], exp["category"], exp["amount_in_cents"], exp["currency"], 
                      exp["currency_symbol"], exp["currency_base_unit"], exp["user_can_edit"], 
                      exp["is_invoiced"], exp["is_billable"], exp["workspace_id"], exp["user_id"],
                      exp["receipt_id"])
        end
      end
      expenses
    end

    def time_entries(options = {})
      options["include"] = "user,story,workspace"
      response = get_request("/time_entries.json", options)
      users = response["users"]
      stories = response["stories"]
      workspaces = response["workspaces"]
      time_entry_data = response["time_entries"]
      results = response["results"]
      time_entries = []
      results.each do |result|
        if result["key"].eql? "time_entries"
          ent = time_entry_data[result["id"]]
          user_json = users[ent["user_id"]]
          workspace_json = workspaces[ent["workspace_id"]]
          story_json = stories[ent["story_id"]]
          time_entries << TimeEntry.new(self.oauth_token, ent["id"], ent["created_at"], ent["updated_at"], 
                                        ent["date_performed"], ent["story_id"], ent["time_in_minutes"],
                                        ent["billable"], ent["notes"], ent["rate_in_cents"], 
                                        ent["currency"], ent["currency_symbol"], ent["currency_base_unit"],
                                        ent["user_can_edit"], ent["workspace_id"], ent["user_id"], 
                                        user_json, workspace_json, story_json)
        end
      end
      time_entries
    end

    def create_time_entry(options)
      unless ["workspace_id", "date_performed", "time_in_minutes"].all? {|k| options.has_key? k}
        raise "Missing required parameters"
      end
      options.keys.each {|key| options["time_entry[#{key}]"] = options.delete(key)}
      response = post_request("/time_entries.json", options)
    end

    def invoices(options={})
      options["include"] = "time_entries,expenses,additional_items,workspaces,user"
      response = get_request("/invoices.json", options)
      invoices_data = response["invoices"]
      time_entries = response["time_entries"]
      expenses = response["expenses"]
      additional_items = response["additional_items"]
      workspaces = response["workspaces"]
      users = response["users"]
      results = response["results"]
      invoices = []
      results.each do |result|
        if result["key"].eql? "invoices"
          inv = invoices_data[result["id"]]
          time_entries_json, expenses_json, additional_items_json, workspaces_json = [], [], [], []
          inv["time_entry_ids"].each {|k| time_entries_json << time_entries[k]}
          inv["additional_item_ids"].each{|k| additional_items_json << additional_items[k]}
          inv["expense_ids"].each{|k| expenses_json << expenses[k]}
          inv["workspace_ids"].each{|k| workspaces_json << workspaces[k]}
          user_json = users[inv["user_id"]]
          invoices << Invoice.new(self.oauth_token, inv["id"], inv["created_at"], inv["updated_at"], 
                              inv["invoice_date"], inv["due_date"], inv["message"], inv["draft"], inv["status"], 
                              inv["balance_in_cents"], inv["currency"], inv["currency_base_unit"], 
                              inv["currency_symbol"], inv["payment_schedule"], inv["workspace_ids"], 
                              inv["user_id"], inv["recipient_id"], time_entries_json, expenses_json, 
                              additional_items_json, workspaces_json, user_json)
        end
      end
      invoices
    end

    # ERROR
    def create_asset(options)
      unless ["data", "type"].all? {|k| options.has_key? k}
        raise "Missing required parameters"
      end
      raise "Type of asset must be 'post' or 'expense'" unless ["post", "expense"].include? options["type"]
      options["data"] = "@" + options["data"]
      options.keys.each {|key| options["asset[#{key}]"] = options.delete(key)}
      response = post_request("/assets.json", options)
    end

    def workspaces(options={})
      options["include"] = "primary_counterpart,participants,creator"
      response = get_request("/workspaces.json", options)
      users = response["users"]
      results = response["results"]
      workspace_data = response["workspaces"]
      workspaces = []
      results.each do |result|
        if result["key"].eql? "workspaces"
          wksp = workspace_data[result["id"]]
          primary_counterpart_json = users[wksp["primary_counterpart_id"]]
          participants_json = []
          wksp["participant_ids"].each {|k| participants_json << users[k]}
          creator_json = users[wksp["creator_id"]]
          workspaces << Workspace.new(self.oauth_token, wksp["id"], wksp["title"], wksp["archived"], 
                                      wksp["description"], wksp["effective_due_date"], wksp["budgeted"], 
                                      wksp["change_orders_enabled"], wksp["updated_at"], wksp["created_at"], 
                                      wksp["consultant_role_name"], wksp["client_role_name"], 
                                      wksp["can_create_line_items"], wksp["default_rate"], 
                                      wksp["currency_symbol"], wksp["currency_base_unit"], 
                                      wksp["can_invite"], wksp["has_budget_access"], wksp["price"], 
                                      wksp["price_in_cent"], wksp["budget_used"], 
                                      wksp["over_budget"], wksp["currency"], primary_counterpart_json,
                                      participants_json, creator_json)
        end
      end
      workspaces
    end

    def create_workspace(options)
      unless ["title", "creator_role"].all? {|k| options.has_key? k}
        raise "Missing required parameters"
      end 
      unless ["buyer", "maven"].include? options["creator_role"]
        raise "creator_role must be 'buyer' or 'maven'"
      end
      options.keys.each {|key| options["workspace[#{key}]"] = options.delete(key)}
      response = post_request("/workspaces.json", options)
    end

  end
end