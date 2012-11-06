require 'chef/config'

# TODO: remove these 'mapping' calls once environments/config templates are
# updated
ChefServerWebui::Config[:chef_server_url] = Chef::Config[:chef_server_url]
ChefServerWebui::Config[:rest_client_name] = Chef::Config[:web_ui_client_name]
ChefServerWebui::Config[:rest_client_key] = Chef::Config[:web_ui_key]
ChefServerWebui::Config[:admin_user_name] =  Chef::Config[:web_ui_admin_user_name]
ChefServerWebui::Config[:admin_default_password] = Chef::Config[:web_ui_admin_default_password]
