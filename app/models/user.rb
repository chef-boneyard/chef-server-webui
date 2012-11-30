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

require 'chef/json_compat'
require 'chef_server_webui/helpers'

class User
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::MassAssignmentSecurity
  include ChefServerWebui::Helpers
  include ChefServerWebui::ApiClientHelper
  extend ChefServerWebui::ApiClientHelper

  #############################################################################
  # Custom Validators
  #############################################################################
  class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      unique = User.load(value) ? false : true
      record.errors.add attribute, "must be unique" unless unique
    end
  end

  attr_accessor :name, :validated, :admin, :password, :password_confirmation
  attr_accessor :public_key, :private_key
  attr_accessor :regenerate_private_key

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
  validates :password, :length => { :minimum => 6,
                                    :unless => Proc.new { |u| u.password.blank? } },
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
    coerce_boolean(admin)
  end

  def regenerate_private_key?
    coerce_boolean(regenerate_private_key)
  end

  def last_admin?
    return false unless admin?
    count = 0
    users = User.list
    users.each do |u, url|
      user = User.load(u)
      if user.admin
        count = count + 1
        return false if count == 2
      end
    end
    return true
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
    # a PUT with private_key = true tells Erchef to regen the keypair
    # https://github.com/opscode/chef_wm/blob/master/src/chef_wm_named_user.erl#L123-136
    result['private_key'] = true if regenerate_private_key?
    result['public_key'] = public_key unless public_key.blank?
    result.to_json(*a)
  end

  # Remove this User via the REST API
  def destroy
    client_with_actor.delete("users/#{@name}")
  end

  # Save this User via the REST API
  def save
    begin
      response = client_with_actor.put("users/#{@name}", self)
      self.private_key = response['private_key'] if response.key?('private_key')
      self.public_key = response['public_key'] if response.key?('public_key')
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        client_with_actor.post("users", self)
      else
        raise e
      end
    end
    self
  end

  # Create the User via the REST API
  def create
    response = client_with_actor.post("users", self)
    self.private_key = response['private_key']
    self.public_key = response['public_key']
    self.persisted = true
    self
  end

  #############################################################################
  # Class Methods
  #############################################################################

  def self.authenticate(name, password)
    if user = self.load(name)
      auth_data = {'name' => name, 'password' => password}
      # we don't use 'client_with_actor' since session[:user] is nil
      result = client.post("authenticate_user", auth_data)
      user = nil unless result['verified']
      user
    end
  end

  def self.list
    client_with_actor.get("users")
  end

  # Load a User by name
  def self.load(name)
    user = nil
    # return nil if name.blank?
    begin
      result = client.get("users/#{name}")
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
