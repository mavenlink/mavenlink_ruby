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

#####Save an expense:
```ruby
#Savable attributes : notes, category, date, amount_in_cents
exp = cl.expenses.first
exp.category = "Updated category"
exp.save
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


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
