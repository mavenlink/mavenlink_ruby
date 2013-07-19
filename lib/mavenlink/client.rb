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
          expenses << Expense.new(self.oauth_token, exp["id"], exp["created_at"], exp["updated_at"], exp["date"], 
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
          time_entries << TimeEntry.new(self.oauth_token, ent["id"], ent["created_at"], ent["updated_at"], 
                                        ent["date_performed"], ent["story_id"], ent["time_in_minutes"],
                                        ent["billable"], ent["notes"], ent["rate_in_cents"], 
                                        ent["currency"], ent["currency_symbol"], ent["currency_base_unit"],
                                        ent["user_can_edit"], ent["workspace_id"], ent["user_id"], 
                                        users, workspaces, stories, options)
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
  end
end