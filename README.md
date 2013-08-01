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
#####Initialize a new client

```ruby
    require 'mavenlink'
    cl = Mavenlink::Client.new(oauth_token)
```
###User
#####Get users
```ruby    
    # All users
    users = cl.users
    
    # Filter responses by participant_in
    filtered_users = cl.users({:participant_in => 12345})
```

###Expense
#####Get expenses
    
```ruby    
    # All expenses
    expenses = cl.expenses
    
    # Filter responses by workspace_id and order by date
    filtered_expenses = cl.expenses({:workspace_id => 12345, :order => "date:asc" })
```

#####Create a new expense
```ruby
#Required parameters : workspace_id, date, category, amount_in_cents
#Optional paramters : notes, currency
cl.create_expense({ :workspace_id => 12345,
                    :date => "2012/01/01",
                    :category => "Travel",
                    :amount_in_cents => 100 
                    })
```

#####Save and reload expense
```ruby
#Savable attributes: notes, category, date, amount_in_cents
exp = cl.expenses.first
exp_copy = cl.expenses.first
exp.category = "Updated category"

# exp.category != exp_copy.category
exp.save

# exp.category == exp_copy.category
exp_copy.reload
```

#####Delete an expense
```ruby
exp = cl.expenses.first
exp.delete
```

###Expense Category
#####Get expense categories
```ruby
# Returns an array of expense category strings
categories = cl.expense_categories
```

###Workspace
#####Get workspaces
```ruby
    # All workspaces
    workspaces = cl.workspaces

    # Filter and search workspaces
    workspaces = @cl.workspaces({:search => "API Test Project"})
```

#####Create a new workspace
```ruby
#Required parameters: title, creator_role(maven or buyer)
#Optional parameters: budgeted, description, currency, price, due_date, project_tracker_template_id
@cl.create_workspace({ :title => "Random Workspace X",
                        :creator_role => "maven"
                    }).
```

#####Save and reload a workspace
```ruby
#Savable attributes: title, budgeted, description, archived
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

###Invoice
#####Get invoices
```ruby
    # All invoices
    invoices = cl.invoices

    # Filter invoices
    invoices = @cl.invoices({:workspace_id => "12345,12346", :paid => "true"})
```

#####Reload a invoice
```ruby
inv = cl.invoices.first
inv.reload
```

#####Associated objects
```ruby
inv = cl.invoices.first

#Time entries of an invoice
time_entries = inv.time_entries

#Expenses of an invoice
expenses = inv.expenses

#Additional items returned as a hash
additional_items = inv.additional_items

#Workspaces related to the invoice
workspaces = inv.workspaces

#Creator of the invoice
user = inv.user
```

###TimeEntry
#####Get time entries
```ruby
    # All time entries
    entries = cl.time_entries

    # Filter invoices
    entries = @cl.entries({:workspace_id => 12345})
```

#####Create a new time entry
```ruby
#Required parameters: workspace_id, date_performed, time_in_minutes
#Optional parameters: billable, notes, rate_in_cents, story_id
ent = @cl.create_time_entry({
                              :workspace_id => 12345,
                              :date_performed => "2013-07-04",
                              :time_in_minutes => 34,
                              :notes => "Notes for TE"
                            })
```

#####Reload and save a time entry
```ruby
Savable attributes: date_performed, time_in_minutes, notes, rate_in_cents, billable
ent = cl.time_entries.first
ent_copy = cl.time_entries.first
ent.time_in_minutes = 10

# ent.category != ent_copy.time_in_minutes
ent.save

# exp.category == exp_copy.category
ent_copy.reload
```
#####Delete an existing time entry
```ruby
ent = cl.time_entry.first
ent.delete
```

#####Associated objects
```ruby
ent = cl.time_entries.first

#Workspace that the entry belongs to
wks = ent.workspace

#User that submitted the entry
user = ent.user

#Story associated with entry. nil if no story.
story = ent.story
```

###Story
#####Get stories
```ruby
    # All stories
    stories = cl.stories

    # Filter and order stories
    stories = @cl.stories({:workspace_id => 12345, :order => "created_at:asc", :parents_only => true})
```

#####Create a new story
```ruby
#Required parameters: workspace_id, title, story_type(task, milestone or deliverable)
#Optional parameters: description, parent_id, start_date, due_date, assignees, budget_estimate_in_cents,
#                     time_estimate_in_minutes, tag_list
stry = @cl.create_story({
                          :workspace_id => 3467515,
                          :title => "New Task",
                          :story_type => "task"
                       })
```

#####Reload and save a story
```ruby
#Savable attributes: title, description, story_type, start_date, due_date,
#                    state, budget_estimate_in_cents, time_estimate_in_minutes, percentage_complete
stry = cl.stories.first
stry_copy = cl.stories.first
stry.description = "Updated description"

# stry.description != stry_copy.description
stry.save

# stry.description == stry_copy.description
stry_copy.reload
```

#####Associated objects
```ruby
stry = cl.stories.first

#Workspace that the story belongs to
workspace = story.workspace

#Parent story, if exists. Nil, otherwise
parent = stry.parent_story

#Array of Users assigned to the story
assignees = stry.assignees

#Sub-stories of this story
sub_stories = stry.sub_stories

#Array of tags as strings
tags = stry.tags
```

###Post
#####Get posts
```ruby
    # All stories
    posts = cl.posts

    # Filter and order posts
    posts = @cl.posts({:workspace_id => 3484825, :parents_only => true})
```

#####Create a new post
```ruby
#Required parameters: message, workspace_id
#Optional parameters: subject_id, subject_type, story_id, recipient_ids, file_ids
pst = @cl.create_post({
                       :message => "Created new post",
                       :workspace_id => 3484825
                      })
```

#####Reload and save a post
```ruby
#Savable attributes: message, story_id
pst = cl.posts.first
pst_copy = cl.posts.first
pst.message = "Updated message"

# pst.message != pst_copy.message
stry.save

# pst.message == pst_copy.message
pst_copy.reload
```

#####Associated objects
```ruby
pst = cl.posts.first

#Workspace that the story belongs to
workspace = pst.workspace

#Parent post, if exists. Nil, otherwise
parent = pst.parent_post

#User who created the post
user = pst.user

#Story associated with this post
story = pst.story

#Replies to this post as an array of Posts
replies = pst.replies

#Recipients of this post as an array of Users
recipients = pst.recipients

#Newest reply to this post, if exists. Nil otherwise.
newest_reply = pst.newest_reply

#User who posted the newest reply
newest_reply_user = pst.newest_reply_user

# An array of urls to associated google docs
google_documents = pst.google_documents

# A list of assets linked to this pst
assets = pst.assets

###Asset
#####Create a new asset
```ruby
# Required parameters: data (filepath of asset), type (expense or post)
@cl.create_asset({
                  :data => "example_file_path",
                  :type => "expense"
                 })
```

#####Save an asset
```ruby
#Savable attributes: file_name
asset.file_name = "updated_file_name"
asset.save
```

#####Delete an asset
```ruby
asset.delete
```
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
