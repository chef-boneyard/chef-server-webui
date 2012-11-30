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

require 'chef/api_client'

class ClientsController < ApplicationController
  respond_to :html, :json
  before_filter :require_login
  before_filter :exclude => [:index, :show] do |controller|
    controller.require_admin(self)
  end

  # GET /clients
  def index
    begin
      @clients_list = client_with_actor.get("clients").keys.sort
    rescue => e
      log_and_flash_exception(e,
        "Could not list clients")
      @clients_list = []
    end
    respond_with @clients_list
  end

  # GET /clients/:id
  def show
    @client = client_with_actor.get("clients/#{params[:id]}")
    respond_with @client
  end

  # GET /clients/:id/edit
  def edit
    @client = begin
                client_with_actor.get("clients/#{params[:id]}")
              rescue => e
                log_and_flash_exception(e,
                  "Could not load client #{params[:id]}")
                Chef::ApiClient.new
              end
    respond_with @client
  end

  # GET /clients/new
  def new
    @client = Chef::ApiClient.new
    respond_with @client
  end

  # POST /clients
  def create
    begin
      response = client_with_actor.post("clients", {:name => params[:name],
                                                    :admin => coerce_boolean(params[:admin]) })
      @private_key = OpenSSL::PKey::RSA.new(response["private_key"])
      @client = client_with_actor.get("clients/#{params[:name]}")
      flash.now[:notice] = "Created Client #{@client.name}. Please copy the following private key as the client's validation key."
      render :show
    rescue => e
      log_and_flash_exception(e, "Could not create client")
      render :new
    end
  end

  # PUT /clients/:id
  def update
    begin
      @client = client_with_actor.get("clients/#{params[:id]}")
      @private_key = nil
      if params[:regen_private_key]
        @private_key = OpenSSL::PKey::RSA.generate(2048)
        @client.public_key(@private_key.public_key.to_s)
      end
      params[:admin] ? @client.admin(true) : @client.admin(false)
      @client = client_with_actor.put("clients/#{params[:id]}", @client)
      notice = "Updated Client #{@client.name}."
      if @private_key
        notice << " Please copy the following private key as the client's validation key."
      end
      flash.now[:notice] = notice
      render :show
    rescue => e
      log_and_flash_exception(e, "Could not update client")
      render :edit
    end
  end

  # DELETE /clients/:id
  def destroy
    begin
      client_with_actor.delete("clients/#{params[:id]}")
      redirect_to clients_url, :notice => "Client #{params[:id]} deleted successfully"
    rescue => e
      log_and_flash_exception(e, "Could not delete client #{params[:id]}")
    end
  end

end

