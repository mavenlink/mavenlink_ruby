require_relative 'helper'
require 'rest_client'
require 'json'

module Mavenlink
  class Client < Base
    include Mavenlink::Helper

    def initialize(oauth_token)
      super(oauth_token)
    end

    def users(options={})
      response = get_request("/users.json", options)
      user_data = response["users"]
      results = response["results"]
      users = []
      results.each do |result|
        if result["key"].eql? "users"
          users << get_user(user_data[result["id"]])
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
      response = get_request("/expenses.json", options)
      results = response["results"]
      expenses_data = response["expenses"]
      expenses = []
      results.each do |result|
        if result["key"].eql? "expenses"
          expenses << get_expense(self.oauth_token, expenses_data[result["id"]])
        end
      end
      expenses
    end

    def create_expense(options)
      unless [:workspace_id, :date, :category, :amount_in_cents].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end
      options.keys.each {|key| options["expense[#{key}]"] = options.delete(key)}
      response = post_request("/expenses.json", options)
      get_expense(self.oauth_token, response["expenses"][response["results"].first["id"]])
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

          workspaces << get_workspace(self.oauth_token, wksp, primary_counterpart_json, participants_json, creator_json)
        end
      end
      workspaces
    end

    def create_workspace(options)
      unless [:title, :creator_role].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end
      unless ["buyer", "maven"].include? options[:creator_role]
        raise InvalidParametersError.new("creator_role must be 'buyer' or 'maven'")
      end
      options.keys.each {|key| options["workspace[#{key}]"] = options.delete(key)}
      response = post_request("/workspaces.json", options)
      get_workspace(self.oauth_token, response["workspaces"][response["results"].first["id"]])
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
          time_entries << get_time_entry(self.oauth_token, ent, user_json, workspace_json, story_json)
        end
      end
      time_entries
    end

    def create_time_entry(options)
      unless [:workspace_id, :date_performed, :time_in_minutes].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end
      options.keys.each {|key| options["time_entry[#{key}]"] = options.delete(key)}
      response = post_request("/time_entries.json", options)
      get_time_entry(self.oauth_token, response["time_entries"][response["results"].first["id"]])
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
          invoices << get_invoice(self.oauth_token, inv, time_entries_json, expenses_json, additional_items_json, workspaces_json, user_json)
        end
      end
      invoices
    end

    def create_asset(options)
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
      Asset.new(self.oauth_token, response["id"], options[:data])
    end

    def stories(options={})
      options["include"] = "workspace,assignees,parent,sub_stories,tags"
      response = get_request("/stories.json", options)
      users = response["users"]
      workspaces = response["workspaces"]
      story_data = response["stories"]
      tags = response["tags"]
      results = response["results"]
      stories = []
      results.each do |result|
        if result["key"].eql? "stories"
          stry = story_data[result["id"]]
          workspace_json = workspaces[stry["workspace_id"]]
          parent_story_json = story_data[stry["parent_id"]]
          assignees_json, sub_stories_json, tags_json = [], [], []
          stry["assignee_ids"].each {|k| assignees_json << users[k]}
          stry["sub_story_ids"].each {|k| sub_stories_json << story_data[k]}
          stry["tag_ids"].each {|k| tags_json << tags[k]}
          stories << get_story(self.oauth_token, stry, workspace_json, parent_story_json, assignees_json, sub_stories_json, tags_json)
        end
      end
      stories
    end

    def create_story(options)
      unless [:title, :story_type, :workspace_id ].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end 
      unless ["milestone", "task", "deliverable"].include? options[:story_type]
        raise InvalidParametersError.new("story_type must be milestone, task or deliverable")
      end
      options.keys.each {|key| options["story[#{key}]"] = options.delete(key)}
      response = post_request("/stories.json", options)
      get_story(self.oauth_token, response["stories"][response["results"].first["id"]])
    end

    def posts(options={})
      options["include"] = "subject,user,workspace,story,replies,newest_reply,newest_reply_user,recipients,google_documents,assets"
      response = get_request("/posts.json", options)
      users = response["users"]
      workspaces = response["workspaces"]
      stories = response["stories"]
      assets = response["assets"]
      posts_data = response["posts"]
      results = response["results"]
      google_documents = response["google_documents"]
      posts = []
      results.each do |result|
        if result["key"].eql? "posts"
          pst = posts_data[result["id"]]
          subject_json = posts_data[pst["subject_id"]] unless pst["subject_id"].nil?
          user_json = users[pst["user_id"]]

          workspace_json = workspaces[pst["workspace_id"]]

          options = {}

          options = extract_associstions_from result, :workspace => ["workspaces", "workspace_id"],
                                                      :assets => ["assets", "asset_ids"],
                                                      :users => ["users", "user_id"]
          posts << Post.new(options)

          {
            :workspace => ["workspaces", "workspace_id"],
            :assets => ["assets", "asset_ids"],
            :users => ["users", "user_id"]
          }.each do |name, (json_root_key, attribute_key)|
            if pst[attribute_key].is_a?(Array)
              options[name] = []
              pst[attribute_key].each do |id|
                options[name].push response[json_root_key][id]
              end
            else
              options[name] = response[json_root_key][pst[attribute_key]]
            end
          end

          # options = {
          #  :workspace => { :title => '...' },
          #  :assets => [ { :path => '...' }, { :path => '...' }, ... ],
          #  ...
          # }


          story_json = stories[pst["story_id"]] unless pst["story_id"].nil?
          newest_reply_json = posts_data[pst["newest_reply_id"]] unless pst["newest_reply_id"].nil?
          newest_reply_user_json = users[pst["newest_reply_user_id"]] unless pst["newest_reply_user_id"].nil?
          recipients_json, google_documents_json = [], []
          assets_json, replies_json = [], []
          pst["recipient_ids"].each {|k| recipients_json << users[k]}
          google_documents_json = google_documents
          pst["asset_ids"].each {|k| assets_json << assets[k]}
          pst["reply_ids"].each {|k| replies_json << posts_data[k]}

          posts << get_post(self.oauth_token, pst, subject_json, user_json, workspace_json,
                            story_json, replies_json, newest_reply_json, newest_reply_user_json, 
                            recipients_json, google_documents_json, assets_json)

          #posts << get_post(:token => oauth_token, :pst => pst, :subject => subject_json, user_json, workspace_json,
          #                  story_json, replies_json, newest_reply_json, newest_reply_user_json,
          #                  recipients_json, google_documents_json, assets_json)


        end
      end
      posts
    end

    def create_post(options)
      unless [:message, :workspace_id].all? {|k| options.has_key? k}
        raise InvalidParametersError.new("Missing required parameters")
      end 
      options.keys.each {|key| options["post[#{key}]"] = options.delete(key)}
      response = post_request("/posts.json", options)
      get_post(self.oauth_token, response["posts"][response["results"].first["id"]])
    end

  end
end