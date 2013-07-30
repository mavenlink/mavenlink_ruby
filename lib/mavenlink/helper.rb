module Mavenlink
	module Helper

		def get_workspace(oauth_token, wksp, primary_counterpart_json=nil, participants_json=nil, creator_json=nil)
      Workspace.new(oauth_token, wksp["id"], wksp["title"], wksp["archived"], 
                    wksp["description"], wksp["effective_due_date"], wksp["budgeted"], 
                    wksp["change_orders_enabled"], wksp["updated_at"], wksp["created_at"], 
                    wksp["consultant_role_name"], wksp["client_role_name"], 
                    wksp["can_create_line_items"], wksp["default_rate"], 
                    wksp["currency_symbol"], wksp["currency_base_unit"], 
                    wksp["can_invite"], wksp["has_budget_access"], wksp["price"], 
                    wksp["price_in_cent"], wksp["budget_used"], wksp["over_budget"], wksp["currency"],
                    primary_counterpart_json, participants_json, creator_json)
		end

		def get_user(usr)
			User.new(usr["id"], usr["full_name"], usr["photo_path"], usr["email_address"], usr["headline"])
		end

		def get_post(oauth_token, pst)
			Post.new(oauth_token, pst["id"], pst["newest_reply_at"], pst["message"], pst["has_attachment"], 
               pst["created_at"], pst["updated_at"], pst["reply_count"], pst["private"], pst["user_id"], 
               pst["workspace_id"], pst["workspace_type"], pst["reply"], pst["subject_id"], 
               pst["subject_type"], pst["story_id"], pst["subject_json"], nil, nil, nil, nil, nil, nil, 
               nil, nil, nil)
		end

		def get_story(oauth_token, stry)
      Story.new(oauth_token, stry["id"], stry["title"], stry["description"], stry["updated_at"], 
                stry["created_at"], stry["due_date"], stry["start_date"], stry["story_type"], 
                stry["state"], stry["position"], stry["archived"], stry["deleted_at"], 
                stry["sub_story_count"], stry["budget_estimate_in_cents"], 
                stry["time_estimate_in_minutes"], stry["workspace_id"], stry["parent_id"], 
                self.workspace_json, nil, nil, nil, nil, stry["percentage_complete"])
		end

		def get_time_entry(oauth_token, ent)
			TimeEntry.new(oauth_token, ent["id"], ent["created_at"], ent["updated_at"], 
                    ent["date_performed"], ent["story_id"], ent["time_in_minutes"],
										ent["billable"], ent["notes"], ent["rate_in_cents"], 
                    ent["currency"], ent["currency_symbol"], ent["currency_base_unit"],
                    ent["user_can_edit"], ent["workspace_id"], ent["user_id"], 
                    nil, nil, nil) 
    end

    def get_expense(oauth_token, exp)
      Expense.new(oauth_token, exp["id"], exp["created_at"], exp["updated_at"], exp["date"], 
                      exp["notes"], exp["category"], exp["amount_in_cents"], exp["currency"], 
                      exp["currency_symbol"], exp["currency_base_unit"], exp["user_can_edit"], 
                      exp["is_invoiced"], exp["is_billable"], exp["workspace_id"], exp["user_id"],
                      exp["receipt_id"])
    end

	end
end