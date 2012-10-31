require 'chef/config'

Chef::Config[:node_name] = Chef::Config[:web_ui_client_name]
Chef::Config[:client_key] = Chef::Config[:web_ui_key]
