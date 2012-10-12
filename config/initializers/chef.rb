require 'chef'
require 'chef/role'
require 'chef/webui_user'

Chef::Config[:node_name] = Chef::Config[:web_ui_client_name]
Chef::Config[:client_key] = Chef::Config[:web_ui_key]

# FIXME: commented out the following so that the webui will at least
# start. Not yet clear where we want to do the initialization

# Create the default admin user "admin" if no admin user exists
# unless Chef::WebUIUser.admin_exist
#   user = Chef::WebUIUser.new
#   user.name = Chef::Config[:web_ui_admin_user_name]
#   user.set_password(Chef::Config[:web_ui_admin_default_password])
#   user.admin = true
#   user.save
# end
