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
  before_filter :require_login
  before_filter :require_admin

  def new
    @databag = Chef::DataBag.new
  end

  def create
    begin
      @databag = Chef::DataBag.new
      Chef::DataBag.validate_name!(params[:name])
      @databag.name params[:name]
      client_with_actor.post("data", @databag)
      redirect_to databags_url, :notice => "Created Databag #{@databag.name}"
    rescue => e
      if e.kind_of?(Chef::Exceptions::InvalidDataBagName)
        flash.now[:error] = e.message
      else
        flash.now[:error] = "Could not create databag"
      end
      render :new
    end
  end

  def index
    @databags = begin
                  client_with_actor.get("data")
                rescue => e
                  flash[:error] = "Could not list databags"
                  {}
                end
  end

  def show
    begin
      @databag = client_with_actor.get("data/#{params[:id]}")
      @databag_name = params[:id]
    rescue => e
      @databags = Chef::DataBag.list
      flash.now[:error] = "Could not load databag"
      render :index
    end
    raise HTTPStatus::NotFound, "Cannot find databag #{params[:id]}" unless @databag
    render :show
  end

  def destroy
    begin
      client_with_actor.delete("data/#{params[:id]}")
      redirect_to databags_url, :notice => "Data bag #{params[:id]} deleted successfully"
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @databags = Chef::DataBag.list
      flash.now[:error] = "Could not delete databag"
      render :index
    end
  end

end
