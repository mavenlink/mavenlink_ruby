module Mavenlink
	module Helper

		def parse_workspace(oauth_token, wksp, opts={})
      Workspace.new(oauth_token, wksp["id"], wksp["title"], wksp["archived"], 
                    wksp["description"], wksp["effective_due_date"], wksp["budgeted"], 
                    wksp["change_orders_enabled"], wksp["updated_at"], wksp["created_at"], 
                    wksp["consultant_role_name"], wksp["client_role_name"], 
                    wksp["can_create_line_items"], wksp["default_rate"], 
                    wksp["currency_symbol"], wksp["currency_base_unit"], 
                    wksp["can_invite"], wksp["has_budget_access"], wksp["price"], 
                    wksp["price_in_cent"], wksp["budget_used"], wksp["over_budget"], wksp["currency"],
                    opts["primary_counterpart_json"], opts["participants_json"], opts["creator_json"])
		end

		def parse_user(usr)
			User.new(usr["id"], usr["full_name"], usr["photo_path"], usr["email_address"], usr["headline"])
		end

		def parse_post(oauth_token, pst, opts={})
			Post.new(oauth_token, pst["id"], pst["newest_reply_at"], pst["message"], pst["has_attachment"],
               pst["created_at"], pst["updated_at"], pst["reply_count"], pst["private"], pst["user_id"], 
               pst["workspace_id"], pst["workspace_type"], pst["reply"], pst["subject_id"], 
               pst["subject_type"], pst["story_id"], opts["subject_json"], opts["user_json"], opts["workspace_json"],
               opts["story_json"], opts["replies_json"], opts["newest_reply_json"], opts["newest_reply_user_json"],
               opts["recipients_json"], opts["google_documents_json"], opts["assets_json"])
		end

		def parse_story(oauth_token, stry, opts={})
      Story.new(oauth_token, stry["id"], stry["title"], stry["description"], stry["updated_at"],
                stry["created_at"], stry["due_date"], stry["start_date"], stry["story_type"],
                stry["state"], stry["position"], stry["archived"], stry["deleted_at"],
                stry["sub_story_count"], stry["budget_estimate_in_cents"],
                stry["time_estimate_in_minutes"], stry["workspace_id"], stry["parent_id"],
                stry["percentage_complete"], opts["workspace_json"], opts["parent_story_json"], opts["assignees_json"],
                opts["sub_stories_json"], opts["tags_json"])
		end

		def parse_time_entry(oauth_token, ent, opts={})
			TimeEntry.new(oauth_token, ent["id"], ent["created_at"], ent["updated_at"], 
                    ent["date_performed"], ent["story_id"], ent["time_in_minutes"],
										ent["billable"], ent["notes"], ent["rate_in_cents"], 
                    ent["currency"], ent["currency_symbol"], ent["currency_base_unit"],
                    ent["user_can_edit"], ent["workspace_id"], ent["user_id"],
                    opts["user_json"], opts["workspace_json"], opts["story_json"])
    end

    def parse_expense(oauth_token, exp)
      Expense.new(oauth_token, exp["id"], exp["created_at"], exp["updated_at"], exp["date"], 
                      exp["notes"], exp["category"], exp["amount_in_cents"], exp["currency"], 
                      exp["currency_symbol"], exp["currency_base_unit"], exp["user_can_edit"], 
                      exp["is_invoiced"], exp["is_billable"], exp["workspace_id"], exp["user_id"],
                      exp["receipt_id"])
    end

    def parse_invoice(oauth_token, inv, opts={})
      Invoice.new(oauth_token, inv["id"], inv["created_at"], inv["updated_at"],
                  inv["invoice_date"], inv["due_date"], inv["message"], inv["draft"], inv["status"],
                  inv["balance_in_cents"], inv["currency"], inv["currency_base_unit"],
                  inv["currency_symbol"], inv["payment_schedule"], inv["workspace_ids"],
                  inv["user_id"], inv["recipient_id"], opts["time_entries_json"], opts["expenses_json"],
                  opts["additional_items_json"], opts["workspaces_json"], opts["user_json"])
    end

    def parse_associated_objects(assoc_hash, pst, response)
      post_options = {}
      assoc_hash.each do |name, (json_root_key, attribute_key)|
        if pst[attribute_key].is_a?(Array)
          post_options["#{name}_json"] = []
          pst[attribute_key].each do |id|
            post_options["#{name}_json"].push response[json_root_key][id]
          end
        else
          post_options["#{name}_json"] = response[json_root_key][pst[attribute_key]]
        end
      end
      post_options
    end

	end
end