#
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

require 'chef/data_bag'

class DatabagsController < ApplicationController

  respond_to :html, :json
  before_filter :login_required
  before_filter :require_admin

  def new
    @databag = Chef::DataBag.new
  end

  def create
    raise HTTPStatus::BadRequest, "Databag name cannot be blank" if params[:name].blank?
    begin
      @databag = Chef::DataBag.new
      @databag.name params[:name]
      @databag.create
      redirect_to databags_url, :notice => "Created Databag #{@databag.name}"
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      flash[:error] = "Could not create databag"
      render :new
    end
  end

  def index
    @databags = begin
                  ChefServer::Client.get("data")
                rescue => e
                  Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                  flash[:error] = "Could not list databags"
                  {}
                end
  end

  def show
    begin
      @databag = ChefServer::Client.get("data/#{params[:id]}")
      raise HTTPStatus::NotFound, "Cannot find databag #{params[:id]}" unless @databag
      display @databag
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @databags = Chef::DataBag.list
      flash[:error] = "Could not load databag"
      render :index
    end
  end

  def destroy
    begin
      ChefServer::Client.delete("data/#{params[:id]}")
      redirect_to databags_url, :notice => "Data bag #{params[:id]} deleted successfully"
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @databags = Chef::DataBag.list
      flash[:error] = "Could not delete databag"
      render :index
    end
  end

end
