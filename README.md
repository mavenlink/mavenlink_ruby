# Mavenlink

Ruby gem for Mavenlink's API v1. 

## Installation

Add this line to your application's Gemfile:

    gem 'mavenlink'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mavenlink

You will need your oauth_token, which can be found on your Mavenlink userpage, to use the client.

## Usage

### Client
#####Initialize a new client:

```ruby
    require 'mavenlink'
    cl = Mavenlink::Client.new(oauth_token)
```
###User
#####Get users:
```ruby    
    # All users
    users = cl.users
    
    # Filter responses by participant_in
    filtered_users = cl.users({:participant_in => 12345})
```

###Expense
#####Get expenses:
    
```ruby    
    # All expenses
    expenses = cl.expenses
    
    # Filter responses by workspace_id and order by date
    filtered_expenses = cl.expenses({:workspace_id => 12345, :order => "date:asc" })
```

#####Create a new expense:
```ruby
#Required parameters : workspace_id, date, category, amount_in_cents
#Optional paramters : notes, currency
cl.create_expense({ :workspace_id => 12345,
                    :date => "2012/01/01",
                    :category => "Travel",
                    :amount_in_cents => 100 
                    })
```

#####Save and reload expense:
```ruby
#Savable attributes : notes, category, date, amount_in_cents
exp = cl.expenses.first
exp_copy = cl.expenses.first
exp.category = "Updated category"

# exp.category != exp_copy.category
exp.save

# exp.category == exp_copy.category
exp_copy.reload
```

#####Delete an expense:
```ruby
exp = cl.expenses.first
exp.delete
```

###Expense Category
#####Get expense categories:
```ruby
# Returns an array of expense category strings
categories = cl.expense_categories
```

###Workspace
#####Get workspaces:
```ruby
    # All workspaces
    workspaces = cl.workspaces

    # Filter and search workspaces
    workspaces = @cl.workspaces({:search => "API Test Project"})
```

#####Create a new workspace:
```ruby
#Required parameters: title, creator_role(maven or buyer)
#Optional parameters: budgeted, description, currency, price, due_date, project_tracker_template_id
@cl.create_workspace({ :title => "Random Workspace X",
                        :creator_role => "maven"
                    }).
```

#####Save and reload workspace:
```ruby
#Savable attributes : title, budgeted, description, archived
wks = cl.workspaces.first
wks_copy = cl.workspaces.first
exp.titile = "Updated title"

# wks.title != wks_copy.title
wks.save

# wks.title == wks_copy.title
wks_copy.reload
```

#####Create a workspace invitation
```ruby
wks = cl.workspaces.first

#Required parameters: full_name, email_address, invitee_role
#Optional parameters: subject, message
wks.create_workspace_invitation({ :full_name => "example name",
                                  :email_address => "name@example.com",
                                  :invitee_role => "maven"
                               })
```

#####Associated objects
```ruby
wks = cl.workspaces.first

#Lead of opposite team
counterpart_user = wks.primary_counterpart

#Array of participating users
participants = wks.participants

#Creator of workspace
creator = wks.creator
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
