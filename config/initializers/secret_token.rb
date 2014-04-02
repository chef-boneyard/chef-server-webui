# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# This file is overwritten with a randomly generated secret token when chef-server-webui is provisioned by Omnibus

# https://github.com/opscode/omnibus-chef-server/blob/master/files/chef-server-cookbooks/chef-server/recipes/chef-server-webui.rb
# https://github.com/opscode/omnibus-chef-server/blob/master/files/chef-server-cookbooks/chef-server/templates/default/secret_token.erb
ChefServerWebui::Application.config.secret_token = 'e50ea2bc0d36f268b1f8fcd5722b7c182f924a1efd579cd62fb46dade9dba29b80cc0937d7c4d854f84de872add3888eb40df21474e8413d666ddaf333c5f368'
