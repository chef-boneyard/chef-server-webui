#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/environment'

class EnvironmentsController < ApplicationController

  respond_to :html, :json
  before_filter :require_login
  before_filter :require_admin, :only => [:create, :update, :destroy]

  # GET /environments
  def index
    @environment_list = begin
                          client_with_actor.get("environments")
                        rescue => e
                          flash[:error] = "Could not list environments"
                          {}
                        end
  end

  # GET /environments/:id
  def show
    load_environment
  end

  # GET /environemnts/new
  def new
    @environment = Chef::Environment.new
    load_cookbooks
    render :new
  end

  # POST /environments
  def create
    raise HTTPStatus::BadRequest, "Environment name cannot be blank" if params[:name].blank?
    @environment = Chef::Environment.new
    if @environment.update_from_params(processed_params=process_params)
      begin
        client_with_actor.post("environments", @environment)
        redirect_to environments_url :notice => "Created Environment #{@environment.name}"
      rescue Net::HTTPServerException => e
        if conflict?(e)
          logger.debug("Got 409 conflict creating environment #{params[:name]}\n#{format_exception(e)}")
          redirect_to new_environment_url, :alert => "An environment with that name already exists"
        elsif forbidden?(e)
          # Currently it's not possible to get 403 here. I leave the code here for completeness and may be useful in the future.[nuo]
          logger.debug("Got 403 forbidden creating environment #{params[:name]}\n#{format_exception(e)}")
          redirect_to new_environment_url, :alert => "Permission Denied. You do not have permission to create an environment."
        else
          logger.error("Error communicating with the API server\n#{format_exception(e)}")
          raise
        end
      end
    else
      load_cookbooks
      # By rendering :new, the view shows errors from @environment.invalid_fields
      render :new
    end
  end

  # GET /environments/:id/edit
  def edit
    load_environment
    if @environment.name == "_default"
      msg = { :warning => "The '_default' environment cannot be edited." }
      redirect_to environments_url, :flash => msg
      return
    end
    load_cookbooks
  end

  # PUT /environments/:id
  def update
    load_environment
    if @environment.update_from_params(process_params(params[:id]))
      begin
        client_with_actor.put("environments/#{params[:id]}", @environment)
        redirect_to environment_url(@environment.name), :notice => "Updated Environment #{@environment.name}"
      rescue Net::HTTPServerException => e
        if forbidden?(e)
          # Currently it's not possible to get 403 here. I leave the code here for completeness and may be useful in the future.[nuo]
          logger.debug("Got 403 forbidden updating environment #{params[:name]}\n#{format_exception(e)}")
          redirect_to edit_environment_url, :alert => "Permission Denied. You do not have permission to update an environment."
        else
          logger.error("Error communicating with the API server\n#{format_exception(e)}")
          raise
        end
      end
    else
      load_cookbooks
      # By rendering :new, the view shows errors from @environment.invalid_fields
      render :edit
    end
  end

  # DELETE /environments/:id
  def destroy
    begin
      client_with_actor.delete("environments/#{params[:id]}")
      redirect_to :environments, :notice => "Environment #{params[:id]} deleted successfully."
    rescue => e
      redirect_to :environments, :alert => "Could not delete environment #{params[:id]}: #{e.message}"
    end
  end

  # GET /environments/:environment_id/cookbooks
  def list_cookbooks
    # TODO: rescue loading the environment
    load_environment
    @cookbooks = begin
                   client_with_actor.get("/environments/#{params[:environment_id]}/cookbooks").inject({}) do |res, (cookbook, url)|
                     # we just want the cookbook name and the version
                     res[cookbook] = url.split('/').last
                     res
                   end
                 rescue => e
                  log_and_flash_exception(e, "Could not load cookbooks for environment #{params[:environment_id]}")
                  {}
                 end
  end

  # GET /environments/:environment_id/nodes
  def list_nodes
    # TODO: rescue loading the environment
    load_environment
    @nodes = begin
               client_with_actor.get("/environments/#{params[:environment_id]}/nodes").keys.sort
             rescue => e
               log_and_flash_exception(e, "Could not load nodes for environment #{params[:environment_id]}")
               []
             end
  end

  # GET /environments/:environment/recipes
  def list_recipes
    respond_with :recipes => list_available_recipes_for(params[:environment_id])
  end

  # GET /environments/:environment_id/set
  def select_environment
    name = params[:environment_id]
    referer = request.referer || nodes_url
    if name == '_none'
      session[:environment] = nil
    else
      # TODO: check if environment exists
      session[:environment] = name
    end
    redirect_to referer
  end

  private

  def load_environment
    id = params[:id] || params[:environment_id]
    @environment = begin
      client_with_actor.get("environments/#{id}")
    rescue Net::HTTPServerException => e
      flash[:error] = "Could not load environment #{id}"
      @environment = Chef::Environment.new
      false
    end
  end

  def load_cookbooks
    begin
      # @cookbooks is a hash, keys are cookbook names, values are their URIs.
      @cookbooks = client_with_actor.get("cookbooks").keys.sort
    rescue Net::HTTPServerException => e
      redirect_to new_environment_url, :alert => "Could not load the list of available cookbooks."
    end
  end

  def process_params(name=params[:name])
    {:name => name, :description => params[:description], :default_attributes => params[:default_attributes], :override_attributes => params[:override_attributes], :cookbook_version => search_params_for_cookbook_version_constraints}
  end

  def search_params_for_cookbook_version_constraints
    cookbook_version_constraints = {}
    index = 0
    params.each do |k,v|
      cookbook_name_box_id = k[/cookbook_name_(\d+)/, 1]
      unless cookbook_name_box_id.nil? || v.nil? || v.empty?
        cookbook_version_constraints[index] = v + " " + params["operator_#{cookbook_name_box_id}"] + " " + params["cookbook_version_#{cookbook_name_box_id}"].strip # e.g. {"0" => "foo > 0.3.0"}
        index = index + 1
      end
    end
    logger.debug("cookbook version constraints are: #{cookbook_version_constraints.inspect}")
    cookbook_version_constraints
  end
end
