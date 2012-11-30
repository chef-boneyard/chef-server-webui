#
# Copyright:: Copyright (c) 2008-2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef_server/rest_client'

module ChefServerWebui
  module ApiClientHelper
    #
    # We customize the behavior of Chef::REST in two important ways:
    #
    # 1. Set the 'x-ops-request-source' request header so all requests are
    #    authenticated as the webui user.
    # 2. Set the client_name of *some* requests to that of the logged-in user
    #    so these requests are effectively authorized as said user.
    #

    DEFAULT_REQUEST_HEADERS = {
      :headers => ChefServerWebui::Application.config.rest_client_custom_http_headers.merge({'x-ops-request-source' => 'web'})
    }.freeze

    # Returns an instance of ChefServer::RestClient with the 'actor' set to the
    # webui client.
    def client
      client_with_actor(ChefServerWebui::Application.config.chef_server_url,
                        ChefServerWebui::Application.config.rest_client_name,
                        ChefServerWebui::Application.config.rest_client_key)
    end

    # Returns an instance of ChefServer::RestClient with the 'actor' set to the
    # current logged in user. The current user is set in
    # Thread.current[:current_user_id] by the Rails appliction using an
    # around_filter
    def client_with_actor(url=Rails.configuration.chef_server_url,
                          actor=Thread.current[:current_user_id],
                          signing_key_filename=ChefServerWebui::Application.config.rest_client_key)
      ChefServer::RestClient.new(url, actor, signing_key_filename, DEFAULT_REQUEST_HEADERS)
    end
  end
end
