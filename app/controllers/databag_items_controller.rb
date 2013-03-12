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

require 'chef/data_bag_item'

class DatabagItemsController < ApplicationController

  respond_to :html, :json
  before_filter :require_login

  def edit
    begin
      @databag_name = params[:databag_id]
      @databag_item_name = params[:id]
      @databag_item = Chef::DataBagItem.from_hash(client_with_actor.get("data/#{params[:databag_id]}/#{params[:id]}"))
      @default_data = @databag_item.raw_data
    rescue => e
      log_and_flash_exception(e, "Could not load the databag item")
    end
  end

  def update
    begin
      @databag_item = Chef::DataBagItem.new
      @databag_item.data_bag params[:databag_id]
      @databag_item.raw_data = Chef::JSONCompat.from_json(params[:json_data])
      raise HTTPStatus::Forbidden, "Updating id is not allowed" unless @databag_item.raw_data['id'] == params[:id] #to be consistent with other objects, changing id is not allowed.
      client_with_actor.put("data/#{params[:databag_id]}/#{params[:id]}", @databag_item)
      redirect_to databag_url(params[:databag_id], @databag_item.name), :notice => "Updated Databag Item #{@databag_item.name}"
    rescue => e
      log_and_flash_exception(e, "Could not update the databag item")
      @databag_item = Chef::DataBagItem.from_hash(client_with_actor.get("data/#{params[:databag_id]}/#{params[:id]}"))
      @default_data = @databag_item
      render :edit
    end
  end

  def new
    @databag_name = params[:databag_id]
    @default_data = {'id'=>''}
  end

  def create
    begin
      @databag_name = params[:databag_id]
      @databag_item = Chef::DataBagItem.new
      @databag_item.data_bag @databag_name
      @databag_item.raw_data = Chef::JSONCompat.from_json(params[:json_data])
      client_with_actor.post("data/#{params[:databag_id]}", @databag_item)
      redirect_to(databag_url(@databag_name), :notice => "Databag item created successfully" )
    rescue => e
      log_and_flash_exception(e, "Could not create databag item")
      if e.kind_of?(Chef::Exceptions::InvalidDataBagItemID)
        @default_data = {'id'=>''}
      end
      render :new
    end
  end

  def index
  end

  def show
    @databag_item = client_with_actor.get("data/#{params[:databag_id]}/#{params[:id]}")
    @databag_name = params[:databag_id]
    @databag_item_name = params[:id]
  end

  def destroy(databag_id=params[:databag_id], item_id=params[:id])
    begin
      client_with_actor.delete("data/#{params[:databag_id]}/#{params[:id]}")
      redirect_to databag_url(databag_id), :notice => "Databag item deleted successfully"
    rescue => e
      log_and_flash_exception(e, "Could not delete databag item")
      redirect_to databag_databag_items_url(databag_id)
    end
  end

end
