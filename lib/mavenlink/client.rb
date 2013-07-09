require "pp"

module Mavenlink
  class Client < Base

    def initialize(oath_token = nil)
      super(oath_token || "d895ad967c8fdfde5dd76952bfd1be85fbbb0211e011f183b6e210953da46f58")
    end

    def users(options = {})
      user_data = get_request("/users.json", options)
      users = []
      user_data = user_data["users"]
      user_data.each do |key, value|
        users << User.new(key, value["full_name"], value["photo_path"], 
                  value["email_address"], value["headline"])
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

    # TODO : No test mavenlink account to test this
    def expenses(options = {})
      expenses_data = get_request("/expenses.json", options)
      expenses = []
    end

  end

end