require 'chef/config'

# TODO: remove these 'mapping' calls once environments/config templates are
# updated
ChefServer::Config[:chef_server_url] = Chef::Config[:chef_server_url]
ChefServer::Config[:web_ui_client_name] = Chef::Config[:web_ui_client_name]
ChefServer::Config[:web_ui_key] = Chef::Config[:web_ui_key]
ChefServer::Config[:web_ui_admin_user_name] =  Chef::Config[:web_ui_admin_user_name]
ChefServer::Config[:web_ui_admin_default_password] = Chef::Config[:web_ui_admin_default_password]

Chef::Config[:node_name] = ChefServer::Config[:web_ui_client_name]
Chef::Config[:client_key] = ChefServer::Config[:web_ui_key]
