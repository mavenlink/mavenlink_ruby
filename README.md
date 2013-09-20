#Mavenlink

Ruby gem for Mavenlink's API v1.

##Installation

Add this line to your application's Gemfile:

    gem 'mavenlink'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mavenlink

##Usage

Please read the API documentation (http://developer.mavenlink.com/) before using the gem.

You will also need your oauth_token, which can be found on your Mavenlink userpage.
###Client
#####Initialize a new client

```ruby
require 'mavenlink'
oauth_token = 'abc123def456'
client = Mavenlink::Client.new(oauth_token)
```

###User
#####Get users
```ruby
# All userss
users = client.users

# Filter users
filtered_users = client.users({:participant_in => 12345})

# User by id
user = client.users({:only => 123}).first
```

###Expense
#####Get expenses

```ruby
# All expenses
expenses = client.expenses

# Filter expenses
filtered_expenses = client.expenses({:workspace_id => 12345, :order => "date:asc" })
```

#####Create a new expense
```ruby
#Required parameters : workspace_id, date, category, amount_in_cents
#Optional paramters : notes, currency
expense = client.create_expense({ :workspace_id => 12345,
                                  :date => "2012/01/01",
                                  :category => "Travel",
                                  :amount_in_cents => 100
                               })
```

#####Save and reload expense
```ruby
#Savable attributes: notes, category, date, amount_in_cents
expense = client.expenses({:only => 1234})
expense_copy = client.expenses({:only => 1234})
expense.category = "Updated category"
# expense.category != expense_copy.category

expense.save

expense_copy.reload
# expense.category == expense_copy.category
```

#####Delete an expense
```ruby
expense = client.expenses({:only => 1234}).first
expense.delete
```

###Expense Category
#####Get expense categories
```ruby
# Returns an array of expense category strings
categories = client.expense_categories
```

###Workspace
#####Get workspaces
```ruby
# All workspaces with all associated objects
workspaces = client.workspaces({:include => "all"})

# Associated objects that can be included: primary_counterpart,participants,creator
workspaces = client.workspaces({:include => ['primary_counterpart', 'creator'])


# Filter and search workspaces
workspaces = client.workspaces({:search => "API Test Project"})
```

#####Create a new workspace
```ruby
#Required parameters: title, creator_role(maven or buyer)
#Optional parameters: budgeted, description, currency, price, due_date, project_tracker_template_id
client.create_workspace({ :title => "Random Workspace X",
                          :creator_role => "maven"
                        })
```

#####Save and reload a workspace
```ruby
#Savable attributes: title, budgeted, description, archived
workspace = client.workspaces({:search => "API Test Project"}, :include => ['creator'])
workspace_copy = client.workspaces({:search => "API Test Project"})
workspace.title = "Updated title"
# workspace.title != workspace_copy.title

workspace.save

workspace_copy.reload
# workspace.title == workspace_copy.title
```

#####Create a workspace invitation
```ruby
workspace = client.workspaces

#Required parameters: full_name, email_address, invitee_role
#Optional parameters: subject, message
workspace.create_workspace_invitation({ :full_name => "example name",
                                        :email_address => "name@example.com",
                                        :invitee_role => "maven"
                                     })
```

#####Associated objects
```ruby
workspace = client.workspaces({:search => "API Test Project"}, :include => ['creator'])
workspace_copy = client.workspaces({:search => "API Test Project"})

#Lead of opposite team
counterpart_user = workspace.primary_counterpart

#Array of participating users
participants = workspace.participants

#Creator of workspace
# Preloaded - doesn't make an api call
creator = workspace.creator

# Not loaded - makes an api call
creator = workspace_copy.creator

# Explicit api call to load primary_counterpart
workspace_copy.reload(['primary_counterpart'])
```

###Invoice
#####Get invoices
```ruby
# All invoices
invoices = client.invoices

# Associated objects that can be included: time_entries,expenses,additional_items,workspaces,user
invoices = client.invoices({:include => ['all'])

# Filter invoices
invoices = client.invoices({:workspace_id => "12345,12346", :paid => "true"})
```

#####Reload a invoice
```ruby
invoice = client.invoices({:only => 1234})
invoice.reload

#Reload only associated time_entries
invoice.reload(['time_entries'])
```

#####Associated objects
```ruby
invoice = client.invoices({:include => ['time_entries','expenses','workspaces','user']).first


#Time entries of an invoice
time_entries = invoice.time_entries

#Expenses of an invoice
expenses = invoice.expenses

#Additional items returned as a hash
#Not loaded - makes an api call
additional_items = invoice.additional_items

#Workspaces related to the invoice
workspaces = invoice.workspaces

#Creator of the invoice
user = invoice.user
```

###TimeEntry
#####Get time entries
```ruby
# All time entries with all associated objects
entries = client.time_entries({:include => 'all'})

# Associated objects that can be included: user,story,workspace
entries = client.time_entries({:include => ['user', 'story'])

# Filter invoices
entries = client.entries({:workspace_id => 12345})
```

#####Create a new time entry
```ruby
#Required parameters: workspace_id, date_performed, time_in_minutes
#Optional parameters: billable, notes, rate_in_cents, story_id
entry = client.create_time_entry({
                                  :workspace_id => 12345,
                                  :date_performed => "2013-07-04",
                                  :time_in_minutes => 34,
                                  :notes => "Notes for TE"
                                 })
```

#####Reload and save a time entry
```ruby
Savable attributes: date_performed, time_in_minutes, notes, rate_in_cents, billable
entry = client.time_entries.first
entry_copy = client.time_entries.first
entry.time_in_minutes = 10
# entry.time_in_minutes != entry_copy.time_in_minutes

entry.save

entry_copy.reload
# entry.time_in_minutes == entry_copy.time_in_minutes
```
#####Delete an existing time entry
```ruby
entry = client.time_entries.first
entry.delete
```

#####Associated objects
```ruby
entry = client.time_entries(:include => 'all').first

#Workspace that the entry belongs to
workspace = entry.workspace

#User that submitted the entry
user = entry.user

#Story associated with entry. nil if no story.
story = entry.story
```

###Story
#####Get stories
```ruby
# All stories
stories = client.stories

# Associated objects that can be included: workspace,assignees,parent,sub_stories,tags
stories = client.stories({:include => ['workspace', 'parent'])

# Filter and order stories
filtered_stories = client.stories({:workspace_id => 12345, :order => "created_at:asc", :parents_only => true})
```

#####Create a new story
```ruby
#Required parameters: workspace_id, title, story_type(task, milestone or deliverable)
#Optional parameters: description, parent_id, start_date, due_date, assignees, budget_estimate_in_cents,
#                     time_estimate_in_minutes, tag_list
story = client.create_story({
                            :workspace_id => 3467515,
                            :title => "New Task",
                            :story_type => "task"
                            })
```

#####Reload and save a story
```ruby
#Savable attributes: title, description, story_type, start_date, due_date,
#                    state, budget_estimate_in_cents, time_estimate_in_minutes, percentage_complete
story = client.stories({:only => 1234})
story_copy = client.stories({:only => 1234})
story.description = "Updated description"
#story.description != story_copy.description

story.save

story_copy.reload
# story.description == story_copy.description
```

#####Associated objects
```ruby
story = client.stories({:include => ['workspace', 'assignees', 'parent', 'tags']}).first

#Workspace that the story belongs to
workspace = story.workspace

#Parent story, if exists. Nil, otherwise
parent = story.parent_story

#Array of Users assigned to the story
assignees = story.assignees

#Sub-stories of this story
#Not loaded - makes an api call
sub_stories = story.sub_stories

#Array of tags as strings
tags = story.tags
```

###Post
#####Get posts
```ruby
# All stories
posts = client.posts

# Associated objects that can be included: subject,user,workspace,story,replies,newest_reply,newest_reply_user,recipients,google_documents,attachments
stories = client.stories({:include => ['subject', 'replies'])

# Filter and order posts
posts = client.posts({:workspace_id => 23456, :parents_only => true})
```

#####Create a new post
```ruby
#Required parameters: message, workspace_id
#Optional parameters: subject_id, subject_type, story_id, recipient_ids, attachment_ids
post = client.create_post({
                            :message => "Created new post",
                            :workspace_id => 3484825
                           })
```

#####Reload and save a post
```ruby
#Savable attributes: message, story_id
post = client.posts.first
post_copy = client.posts.first
post.message = "Updated message"
# post.message != post_copy.message

post.save

post_copy.reload
# post.message == post_copy.message
```

#####Associated objects
```ruby
post = client.posts(:include => 'all').first

#Workspace that the story belongs to
workspace = post.workspace

#Parent post, if exists. Nil, otherwise
parent = post.parent_post

#User who created the post
user = post.user

#Story associated with this post
story = post.story

#Replies to this post as an array of Posts
replies = post.replies

#Recipients of this post as an array of Users
recipients = post.recipients

#Newest reply to this post, if exists. Nil otherwise.
newest_reply = post.newest_reply

#User who posted the newest reply
newest_reply_user = post.newest_reply_user

# An array of urls to associated google docs
google_documents = post.google_documents

# A list of attachments linked to this post
attachments = post.attachments
```

###Asset
#####Create a new attachment
```ruby
# Required parameters: data (filepath of attachment), type (receipt or post_attachment)
attachment = client.create_attachment({
                             :data => "example_file_path",
                             :type => "receipt"
                            })
```

#####Save an attachment
```ruby
#Savable attributes: file_name
attachment.file_name = "updated_file_name"
attachment.save
```

#####Delete an attachment
```ruby
attachment.delete
```
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
