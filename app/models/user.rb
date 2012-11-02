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
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::MassAssignmentSecurity

  #############################################################################
  # Custom Validators
  #############################################################################
  class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      begin
        unique = User.load(value) ? false : true
      rescue Net::HTTPServerException => e
        unique = true if e.response.code == "404"
      end
      record.errors.add attribute, "must be unique" unless unique
    end
  end

  attr_accessor :name, :validated, :admin, :password, :password_confirmation
  attr_accessor :public_key

  # TODO: delete when Erchef users enpoint is updated
  attr_accessor :openid

  # Rails compat methods
  attr_accessor :persisted
  alias_method :persisted?, :persisted # used by Rails to determine create vs update
  alias :id :name

  def new_record?
    !persisted?
  end

  #############################################################################
  # Validations
  #############################################################################
  validates :name, :presence => true,
                   :uniqueness => {:on => :create}
  validates :password, :length => { :minimum => 6 },
                       :confirmation => true,
                       :presence => { :on => :create }

  # Create a new User object.
  def initialize(attributes={})
    assign_attributes(attributes)
    @admin = attributes['admin'] || false
    @persisted = attributes['persisted'] || false
  end

  def assign_attributes(values, options = {})
    sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
      send("#{k}=", v)
    end
  end

  def name=(n)
    @name = n.gsub(/\./, '_')
  end

  def admin?
    if admin.is_a?(String) && admin.blank?
      nil
    else
      [true, 1, '1', 't', 'T', 'true', 'TRUE'].include?(admin)
    end
  end

  # Serialize this object as a hash
  def to_json(*a)
    attributes = Hash.new
    recipes = Array.new
    result = {
      'name' => name,
      'admin' => admin?
    }
    # ensures we don't send empty password values to Erchef
    result['password'] = password unless password.blank?
    result.to_json(*a)
  end

  # Remove this User via the REST API
  def destroy
    Chef::REST.new(Chef::Config[:chef_server_url]).delete_rest("users/#{@name}")
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
    Chef::REST.new(Chef::Config[:chef_server_url]).post_rest("users", self)
    self
  end

  #############################################################################
  # Class Methods
  #############################################################################

  def self.authenticate(name, password)
    if user = self.load(name)
      auth_data = {'name' => name, 'password' => password}
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      result = r.post_rest("authenticate_user", auth_data)
      user = nil unless result['verified']
      user
    end
  end

  def self.list
    Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("users")
  end

  # Load a User by name
  def self.load(name)
    user = nil
    # return nil if name.blank?
    begin
      result = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("users/#{name}")
      # persisted? is used by Rails to determine create vs update
      result.merge!('persisted' => true) if result
      user = User.new(result)
    rescue Net::HTTPServerException => e
      # user we are authenitcating as may not exist
      raise e unless e.response.code == "404"
    end
    user
  end
end
