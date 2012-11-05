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

require 'forwardable'
require 'mixlib/config'

module ChefServer
  class Config
    extend Mixlib::Config

    chef_server_url nil
    web_ui_client_name nil
    web_ui_key nil
    web_ui_admin_user_name nil
    web_ui_admin_default_password nil
  end

  class Client
    extend Forwardable

    def_delegator :@client, :get_rest
    def_delegator :@client, :post_rest
    def_delegator :@client, :put_rest
    def_delegator :@client, :delete_rest
    def_delegator :@client, :fetch

    def initialize(chef_server_url=ChefServer::Config[:chef_server_url])
      @client = Chef::REST.new(chef_server_url)
    end

    def search(type, query)
      Chef::Search::Query.new.search(type, query)
    end

    def list_search_indexes
      Chef::Search::Query.new.list_indexes
    end

    ###########################################################################
    # Class Methods
    ###########################################################################

    def self.client
      @@client = ChefServer::Client.new
    end

    private_class_method :client

    # Dynamicall define some wrapper class methods for Chef::REST
    class << self
      [:get, :post, :put, :delete].each do |method|
        define_method method do |*args|
          begin
            client.send("#{method}_rest".to_sym, *args)
          rescue => e
            Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
            raise e
          end
        end
      end

      [:fetch, :search, :list_search_indexes].each do |method|
        define_method method do |*args|
          begin
            client.send(method, *args)
          rescue => e
            Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
            raise e
          end
        end
      end
    end

  end
end
