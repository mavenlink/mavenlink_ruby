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

  class Expense < Base
    attr_accessor :id, :created_at, :updated_at, :date, :notes, :category, :amount_in_cents, :currency,
                  :curreny_symbol, :currency_base_unit, :user_can_edit, :is_invoiced, :is_billable, 
                  :workspace_id, :user_id, :receipt_id
    def initialize(id, created_at, updated_at, date, notes, category, amount_in_cents, currency,
                  curreny_symbol, currency_base_unit, user_can_edit, is_invoiced, is_billable, 
                  workspace_id, user_id, receipt_id)
      self.id = id
      self.created_at = created_at
      self.updated_at = updated_at
      self.date = date
      self.notes = notes
      self.category = category
      self.amount_in_cents = amount_in_cents
      self.currency = currency
      self.curreny_symbol = curreny_symbol
      self.currency_base_unit = currency_base_unit
      self.user_can_edit = user_can_edit
      self.is_invoiced = is_invoiced
      self.is_billable = is_billable
      self.workspace_id = self.workspace_id
      self.user_id = user_id
      self.receipt_id = receipt_id
    end
  end

end