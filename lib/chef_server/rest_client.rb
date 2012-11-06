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

require 'chef/config'
require 'forwardable'

module ChefServer
  class RestClient
    extend Forwardable

    attr_reader :client

    def_delegator :@client, :get_rest
    def_delegator :@client, :post_rest
    def_delegator :@client, :put_rest
    def_delegator :@client, :delete_rest
    def_delegator :@client, :fetch

    def initialize(chef_server_url,
                   client_name,
                   signing_key_filename,
                   options={})
      @client = Chef::REST.new(chef_server_url,
                               client_name,
                               signing_key_filename,
                               options)
      # Set values in the Chef::Config class so Chef::Search::Query receives
      # the correct values
      Chef::Config[:chef_server_url] = chef_server_url
      Chef::Config[:node_name] = client_name
      Chef::Config[:client_key] = signing_key_filename
    end

    [:get, :post, :put, :delete].each do |method|
      define_method method do |*args|
        begin
          @client.send("#{method}_rest".to_sym, *args)
        rescue => e
          Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
          raise e
        end
      end
    end

    [:fetch].each do |method|
      define_method method do |*args|
        begin
          @client.send(method, *args)
        rescue => e
          Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
          raise e
        end
      end
    end

    def search(*args, &block)
      Chef::Search::Query.new.search(*args, &block)
    end

    def list_search_indexes
      Chef::Search::Query.new.list_indexes
    end

  end
end
