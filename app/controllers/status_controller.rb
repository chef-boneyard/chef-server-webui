#
# Author:: Joe Williams (joe@joetify.com)
# Author:: Nuo Yan (nuo@opscode.com)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/node'

class StatusController < ApplicationController

  respond_to :html
  before_filter :require_login

  def index
    begin
      @status = if session[:environment]
        generate_status_hash("chef_environment:#{session[:environment]}")
      else
        generate_status_hash("*:*")
      end
    rescue => e
      log_and_flash_exception(e, "Could not list status")
      @status = {}
    end
  end

  private

  def generate_status_hash(query)
    result = Hash.new
    args = { 
      'name'             => [ 'name' ], 
      'platform'         => [ 'platform' ], 
      'platform_version' => [ 'platform_version' ], 
      'fqdn'             => [ 'fqdn' ], 
      'ipaddress'        => [ 'ipaddress' ], 
      'uptime'           => [ 'uptime' ], 
      'ohai_time'        => [ 'ohai_time' ], 
      'run_list'         => [ 'run_list' ]
    }
    limit = if params[:limit]
      # Accept limit of rows returned from query string parameter if specified
      params[:limit].to_i
    else
      # Otherwise arbitrarily set limit
      1000
    end
    client_with_actor.post("search/node?q="+query+"&sort=&start=0&rows=#{limit}", args)["rows"].each do |n|
      result[n['data']['name']] = n['data'] unless n.nil?
    end
    result
  end

end
