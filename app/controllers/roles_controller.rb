#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/role'

class RolesController < ApplicationController

  respond_to :html
  before_filter :require_login
  before_filter :require_admin, :only => [:destroy]

  # GET /roles
  def index
    @role_list =  begin
                   client_with_actor.get("roles")
                  rescue => e
                    log_and_flash_exception(e, "Could not list roles")
                    {}
                  end
  end

  # GET /roles/:id
  def show
    @role = client_with_actor.get("roles/#{params[:id]}")
    @current_env = session[:environment] || "_default"
    @env_run_list_exists = @role.env_run_lists.has_key?(@current_env)
    @run_list = @role.run_list_for(@current_env)
    @recipes = @run_list.expand(@current_env, 'server', {:rest=>client_with_actor}).recipes
  end

  # GET /roles/new
  def new
    begin
      @role = Chef::Role.new
      @available_roles = client_with_actor.get("roles").keys.sort
      @environments = client_with_actor.get("environments").keys.sort
      @run_lists = @environments.inject({}) { |run_lists, env| run_lists[env] = @role.env_run_lists[env]; run_lists}
      @current_env = "_default"
      @available_recipes = list_available_recipes_for(@current_env)
      @existing_run_list_environments = @role.env_run_lists.keys
      # merb select helper has no :include_blank => true, so fix the view in the controller.
      @existing_run_list_environments.unshift('')
    rescue => e
      log_and_flash_exception(e,
        "Could not load available recipes, roles, or the run list.")
    end
  end

  # GET /roles/:id/edit
  def edit
    begin
      @role = client_with_actor.get("roles/#{params[:id]}")
      @available_roles = client_with_actor.get("roles").keys.sort
      @environments = client_with_actor.get("environments").keys.sort
      @current_env = session[:environment] || "_default"
      @run_list = @role.run_list
      @run_lists = @environments.inject({}) { |run_lists, env| run_lists[env] = @role.env_run_lists[env]; run_lists}
      @existing_run_list_environments = @role.env_run_lists.keys
      # merb select helper has no :include_blank => true, so fix the view in the controller.
      @existing_run_list_environments.unshift('')
      @available_recipes = list_available_recipes_for(@current_env)
    rescue => e
      log_and_flash_exception(e,
        "Could not load role #{params[:id]}")
      redirect_to roles_url
    end
  end

  # POST /roles
  def create
    #raise HTTPStatus::BadRequest, "Role name cannot be blank" if params[:name].blank?
    begin
      @role = Chef::Role.new
      @role.name(params[:name])
      @role.env_run_lists(normalize_env_run_lists(params[:env_run_lists]))
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(Chef::JSONCompat.from_json(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(Chef::JSONCompat.from_json(params[:override_attributes])) if params[:override_attributes] != ''
      client_with_actor.post("roles", @role)
      redirect_to roles_url, :notice => "Created Role #{@role.name}"
    rescue => e
      log_and_flash_exception(e, "Could not create role. #{e.message}")
      redirect_to new_role_url
    end
  end

  # PUT /roles/:id
  def update
    begin
      @role = client_with_actor.get("roles/#{params[:id]}")
      @role.env_run_lists(normalize_env_run_lists(params[:env_run_lists]))
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(Chef::JSONCompat.from_json(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(Chef::JSONCompat.from_json(params[:override_attributes])) if params[:override_attributes] != ''
      client_with_actor.put("roles/#{params[:id]}", @role)
      redirect_to role_url(params[:id]), :notice => "Updated Role"
    rescue => e
      log_and_flash_exception(e,
        "Could not update role #{params[:id]}. #{e.message}")
      redirect_to edit_role_url(params[:id])
    end
  end

  # DELETE /roles/:id
  def destroy
    begin
      client_with_actor.delete("roles/#{params[:id]}")
      redirect_to roles_url, :notice => "Role #{params[:id]} deleted successfully."
    rescue => e
      log_and_flash_exception(e, "Could not delete role #{params[:id]}")
      redirect_to roles_url
    end
  end

  private

  # Ensures we don't send Erchef invalid run_list values..ie:
  #
  #    "run_list":["recipe[]"]
  #
  # Basically we want to ensure we turn:
  #
  #    {"_default" => ""}
  #
  # into
  #
  #    {"_default" => []}
  #
  def normalize_env_run_lists(env_run_lists)
    # Make sure we aren't dealing with an ActiveSupport::HashWithIndifferentAccess
    erl = env_run_lists.to_hash
    # LOOk...it's Hash#map
    erl.merge(erl){|k,v| v.blank? ? [] : v }
  end

end
