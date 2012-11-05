#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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

require 'chef/node'

class NodesController < ApplicationController

  respond_to :html

  before_filter :login_required
  before_filter :require_admin, :only => [:destroy]

  def index
    node_hash = if session[:environment]
                  ChefServer::Client.get("environments/#{session[:environment]}/nodes")
                else
                  ChefServer::Client.get("nodes")
                end
    @node_list = node_hash.keys.sort
  rescue => e
    flash.local[:error] = "Could not list nodes"
    @node_hash = {}
  end

  def show
    begin
      @node = ChefServer::Client.get("nodes/#{params[:id]}")
    rescue => e
      flash.now[:error] = "Could not load node #{params[:id]}"
      @node = Chef::Node.new
    end
  end

  def new
    begin
      @node = Chef::Node.new
      @node.chef_environment(session[:environment] || "_default")
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = ChefServer::Client.get("roles").keys.sort
      @run_list = @node.run_list
      @env = session[:environment]
    rescue => e
      redirect_to :nodes, :alert => "Could not load available recipes, roles, or the run list"
    end
  end

  def edit
    begin
      @node = ChefServer::Client.get("nodes/#{params[:id]}")
      @env = @node.chef_environment
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = ChefServer::Client.get("roles").keys.sort
      @run_list = @node.run_list
    rescue => e
      @node = Chef::Node.new
      @available_recipes = []
      @available_roles = []
      @run_list = []
      flash.now[:error] = "Could not load node #{params[:id]}"
    end
  end

  def create
    raise HTTPStatus::BadRequest, "Node name cannot be blank" if params[:name].blank?
    begin
      @node = Chef::Node.new
      @node.name params[:name]
      @node.chef_environment params[:chef_environment]
      @node.normal_attrs = Chef::JSONCompat.from_json(params[:attributes])
      @node.run_list.reset!(params[:for_node] ? params[:for_node] : [])
      ChefServer::Client.post("nodes", @node)
      redirect_to :nodes, :notice => "Created Node #{@node.name}"
    rescue => e
      @node.normal_attrs = Chef::JSONCompat.from_json(params[:attributes])
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = ChefServer::Client.get("roles").keys.sort
      @node.run_list params[:for_node]
      @run_list = @node.run_list
      flash.now[:error] = "Exception raised creating node, #{e.message.length <= 150 ? e.message : "please check logs for details"}"
      render :new
    end
  end

  def update
    begin
      @node = ChefServer::Client.get("nodes/#{params[:id]}")
      @node.chef_environment(params[:chef_environment])
      @node.run_list.reset!(params[:for_node] ? params[:for_node] : [])
      @node.normal_attrs = Chef::JSONCompat.from_json(params[:attributes])
      @node = ChefServer::Client.put("nodes/#{params[:id]}", @node)
      flash.now[:notice] = "Updated Node"
      render :show
    rescue => e
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = ChefServer::Client.get("roles").keys.sort
      @run_list = Chef::RunList.new
      @run_list.reset!(params[:for_node])
      flash.now[:error] = "Exception raised updating node, #{e.message.length <= 150 ? e.message : "please check logs for details"}"
      render :edit
    end
  end

  def destroy
    begin
      ChefServer::Client.delete("nodes/#{params[:id]}")
      redirect_to :nodes, :notice => "Node #{params[:id]} deleted successfully"
    rescue => e
      redirect_to :nodes, :alert => "Could not delete the node"
    end
  end

end
