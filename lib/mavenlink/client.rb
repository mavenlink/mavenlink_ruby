require 'rest_client'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'

module Mavenlink
  class Client < Base

    def initialize(oauth_token, lazy_load=false)
      super(oauth_token, {}, {})
      $lazy_load = lazy_load
    end

    def users(options={})
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      response = get_request("/users.json", options)
      user_data = response["users"]
      results = response["results"]
      users = []
      results.each do |result|
        if result["key"].eql? "users"
          users << User.new(self.oauth_token, user_data[result["id"]])
        end
      end
      users
    end

    def expense_categories
      expense_categories = get_request("/expense_categories.json")
      categories = []
      expense_categories.each {|category| categories << category}
      categories
    end

    def expenses(options={})
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      response = get_request("/expenses.json", options)
      results = response["results"]
      expenses_data = response["expenses"]
      expenses = []
      results.each do |result|
        if result["key"].eql? "expenses"
          expenses << Expense.new(self.oauth_token, expenses_data[result["id"]])
        end
      end
      expenses
    end

    def create_expense(options)
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      unless [:workspace_id, :date, :category, :amount_in_cents].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end
      options.keys.each {|key| options["expense[#{key}]"] = options.delete(key)}
      response = post_request("/expenses.json", options)
      Expense.new(self.oauth_token, response["expenses"][response["results"].first["id"]])
    end

    def workspaces(options={})
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      options["include"] = "primary_counterpart,participants,creator" if !$lazy_load
      response = get_request("/workspaces.json", options)
      results = response["results"]
      workspace_data = response["workspaces"]
      workspaces = []
      results.each do |result|
        if result["key"].eql? "workspaces"
          wksp = workspace_data[result["id"]]
          assoc_hash =  {
                          :primary_counterpart => ["users", "primary_counterpart_id"],
                          :participants => ["users", "participant_ids"],
                          :creator => ["users", "creator_id"]
                        }
          wksp_options = parse_associated_objects(assoc_hash, wksp, response)
          workspaces << Workspace.new(self.oauth_token, wksp, wksp_options)
        end
      end
      workspaces
    end

    def create_workspace(options)
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      unless [:title, :creator_role].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end
      unless ["buyer", "maven"].include? options[:creator_role]
        raise InvalidParametersError.new("creator_role must be 'buyer' or 'maven'")
      end
      options.keys.each {|key| options["workspace[#{key}]"] = options.delete(key)}
      response = post_request("/workspaces.json", options)
      Workspace.new(self.oauth_token, response["workspaces"][response["results"].first["id"]])
    end

    def time_entries(options={})
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      options["include"] = "user,story,workspace"
      response = get_request("/time_entries.json", options)
      time_entry_data = response["time_entries"]
      results = response["results"]
      time_entries = []
      results.each do |result|
        if result["key"].eql? "time_entries"
          ent = time_entry_data[result["id"]]
          assoc_hash =  {
                          :user => ["users", "user_id"],
                          :workspace => ["workspaces", "workspace_id"],
                          :story => ["stories", "story_id"]
                        }
          ent_options = parse_associated_objects(assoc_hash, ent, response)
          time_entries << TimeEntry.new(self.oauth_token, ent, ent_options)
        end
      end
      time_entries
    end

    def create_time_entry(options)
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      unless [:workspace_id, :date_performed, :time_in_minutes].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end
      options.keys.each {|key| options["time_entry[#{key}]"] = options.delete(key)}
      response = post_request("/time_entries.json", options)
      TimeEntry.new(self.oauth_token, response["time_entries"][response["results"].first["id"]])
    end

    def invoices(options={})
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      options["include"] = "time_entries,expenses,additional_items,workspaces,user"
      response = get_request("/invoices.json", options)
      invoices_data = response["invoices"]
      results = response["results"]
      invoices = []
      results.each do |result|
        if result["key"].eql? "invoices"
          inv = invoices_data[result["id"]]
          assoc_hash =  {
                          :workspaces => ["workspaces", "workspace_ids"],
                          :time_entries => ["time_entries", "time_entry_ids"],
                          :additional_items => ["additional_items", "additional_item_ids"],
                          :expenses => ["expenses", "expense_ids"],
                          :user => ["users", "user_id"]
                        }
          inv_options = parse_associated_objects(assoc_hash, inv, response)
          invoices << Invoice.new(oauth_token, inv, inv_options)
        end
      end
      invoices
    end

    def create_asset(options)
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      unless [:data, :type].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end
      raise "Type of asset must be 'post' or 'expense'" unless ["post", "expense"].include? options[:type]
      request = RestClient::Request.new(
                                        :method => :post,
                                        :url => "https://api.mavenlink.com/api/v1/assets.json",
                                        :headers => { "Authorization" => "Bearer #{self.oauth_token}"},
                                        :payload => {
                                                    :multipart => true,
                                                    "asset[data]" => File.new(options[:data], 'rb'),
                                                    "asset[type]" => options[:type]
                                        })
      response = JSON.parse(request.execute)
      Asset.new(oauth_token, {"id" => response["id"], "file_name" =>options[:data]})
    end

    def stories(options={})
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      options["include"] = "workspace,assignees,parent,sub_stories,tags"
      response = get_request("/stories.json", options)
      story_data = response["stories"]
      results = response["results"]
      stories = []
      results.each do |result|
        if result["key"].eql? "stories"
          story = story_data[result["id"]]
          assoc_hash =  {
                          :workspace => ["workspaces", "workspace_id"],
                          :parent_story => ["stories", "parent_id"],
                          :assignees => ["users", "assignee_ids"],
                          :sub_stories => ["stories", "sub_story_ids"],
                          :tags => ["tags", "tag_ids"]
                        }

          story_options = parse_associated_objects(assoc_hash, story, response)
          stories << Story.new(oauth_token, story, story_options)
        end
      end
      stories
    end

    def create_story(options)
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      unless [:title, :story_type, :workspace_id ].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end 
      unless %w[milestone task deliverable].include? options[:story_type]
        raise InvalidParametersError.new("story_type must be milestone, task or deliverable")
      end
      options.keys.each {|key| options["story[#{key}]"] = options.delete(key)}
      response = post_request("/stories.json", options)
      Story.new(oauth_token, response["stories"][response["results"].first["id"]])
    end

    def posts(options={})
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      options["include"] = "subject,user,workspace,story,replies,newest_reply,newest_reply_user,recipients,google_documents,assets"
      response = get_request("/posts.json", options)
      results = response["results"]
      posts_data = response["posts"]
      posts = []
      results.each do |result|
        if result["key"].eql? "posts"
          post = posts_data[result["id"]]

          assoc_hash =  {
                          :workspace => ["workspaces", "workspace_id"],
                          :assets => ["assets", "asset_ids"],
                          :user => ["users", "user_id"],
                          :subject => ["posts", "subject_id"],
                          :story => ["stories", "story_id"],
                          :newest_reply => ["posts", "newest_reply_id"],
                          :newest_reply_user => ["users", "newest_reply_user_id"],
                          :recipients => ["users", "recipient_ids"],
                          :replies => ["posts", "reply_ids"],
                          :google_documents => ["google_documents", "google_document_ids"]
                        }
          post_options = parse_associated_objects(assoc_hash, post, response)
          posts << Post.new(oauth_token, post, post_options)
        end
      end
      posts
    end

    def create_post(options)
      options = HashWithIndifferentAccess.new_from_hash_copying_default(options)
      unless [:message, :workspace_id].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end 
      options.keys.each {|key| options["post[#{key}]"] = options.delete(key)}
      response = post_request("/posts.json", options)
      Post.new(self.oauth_token, response["posts"][response["results"].first["id"]])
    end

  end
end