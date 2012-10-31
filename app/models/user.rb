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
require 'digest/sha1'
require 'chef/json_compat'

class User

  attr_accessor :name, :validated, :admin
  attr_reader   :password

  # Create a new User object.
  def initialize(opts={})
    @name, @password = opts['name'], opts['password']
    @admin = false
  end

  def name=(n)
    @name = n.gsub(/\./, '_')
  end

  def admin?
    admin
  end

  # Set the password for this object.
  def set_password(password, confirm_password=password)
    raise ArgumentError, "Passwords do not match" unless password == confirm_password
    raise ArgumentError, "Password cannot be blank" if (password.nil? || password.length==0)
    raise ArgumentError, "Password must be a minimum of 6 characters" if password.length < 6
    @password = password
  end

  # Serialize this object as a hash
  def to_json(*a)
    attributes = Hash.new
    recipes = Array.new
    result = {
      'name' => name,
      'password' => password,
      'admin' => admin
    }
    result.to_json(*a)
  end

  # Remove this User via the REST API
  def destroy
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    r.delete_rest("users/#{@name}")
  end

  # Save this User via the REST API
  def save
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    begin
      r.put_rest("users/#{@name}", self)
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        r.post_rest("users", self)
      else
        raise e
      end
    end
    self
  end

  # Create the User via the REST API
  def create
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    r.post_rest("users", self)
    self
  end

  #############################################################################
  # Class Methods
  #############################################################################

  def self.authenticate(name, password)
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    r.post_rest("authenticate_user", {'name' => name, 'password' => password})
  end

  # Create a User from JSON
  def self.json_create(o)
    me = new(o)
    me.admin = o["admin"]
    me
  end

  def self.list(inflate=false)
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    if inflate
      response = Hash.new
      Chef::Search::Query.new(Chef::Config[:chef_server_url]).search(:user) do |n|
        response[n.name] = n unless n.nil?
      end
      response
    else
      r.get_rest("users")
    end
  end

  # Load a User by name
  def self.load(name)
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    r.get_rest("users/#{name}")
  end

  # Whether or not there is an User with this key.
  def self.has_key?(name)
    raise "NOT YET IMPLEMENTED"
    #Chef::CouchDB.new.has_key?("webui_user", name)
  end

end
