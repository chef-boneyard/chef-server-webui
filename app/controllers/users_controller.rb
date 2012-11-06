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

class UsersController < ApplicationController

  respond_to :html

  before_filter :login_required, :except => [:login, :login_exec, :complete]
  before_filter :except => [:login, :login_exec, :complete,
                            :show, :edit, :logout, :destroy] do |controller|

    controller.require_admin(self)
  end

  before_filter :only => :destroy do |controller|
    delete_user_check!(params[:id])
  end

  # List users, only if the user is admin.
  def index
    @users = User.list
  rescue => e
    set_user_and_redirect
  end

  # Edit user. Admin can edit everyone, non-admin user can only edit itself.
  def edit
    @user = User.load(params[:id])
  rescue => e
    set_user_and_redirect
  end

  # Show the details of a user. If the user is not admin, only able to show itself; otherwise able to show everyone
  def show
    @user = User.load(params[:id])
  rescue => e
    set_user_and_redirect
  end

  # PUT to /users/:id/update
  def update
    @user = User.load(params[:id])
    @user.assign_attributes(params[:user])

    if @user.name == session[:user] && !@user.admin?
      session[:level] = :user
    end

    if @user.valid?(:update)
      @user.save
      redirect_to :user, :notice => "Updated user #{@user.name}."
    else
      render :edit
    end
  rescue => e
    flash.now[:error] = "Could not update user #{@user.name}."
    render :edit
  end

  def new
    @user = User.new
  rescue => e
    set_user_and_redirect
  end

  def create
    @user = User.new(params[:user])
    if @user.valid?(:create)
      @user.create
      redirect_to :users, :notice => "Created user #{@user.name}."
    else
      render :new
    end
  rescue => e
    flash.now[:error] = "Could not create user: #{$!}"
    session[:level] != :admin ? set_user_and_redirect : (render :new)
  end

  def login
    @user = User.new
    if session[:user]
      redirect_to :nodes, :flash => { :warning => "You've already logged in with user #{session[:user]}" }
    else
      render :layout => 'login'
    end
  end

  def login_exec
    if @user = User.authenticate(params[:name], params[:password])
      session[:user] = params[:name]
      session[:level] = (@user.admin? ? :admin : :user)
      # Nag the admin to change the default password
      if (@user.name == ChefServerWebui::Config[:admin_user_name] &&
            User.authenticate(ChefServerWebui::Config[:admin_user_name], ChefServerWebui::Config[:admin_default_password]))
        redirect_to(edit_user_url(@user.name), :flash => { :warning => "Please change the default password" })
      else
        redirect_back_or_default(:nodes)
      end
    else
      redirect_to :login_users, :alert => "Could not complete logging in."
    end
  end

  def logout
    cleanup_session
    redirect_to top_url
  end

  def destroy
    @user = User.load(params[:id])
    @user.destroy

    if params[:id] == session[:user]
      logout
    else
      redirect_to :users, :notice => "User #{params[:id]} deleted successfully."
    end
  rescue => e
    session[:level] != :admin ? set_user_and_redirect : redirect_to_list_users({ :error => $! })
  end

  private

  def set_user_and_redirect
    begin
      @user = User.load(session[:user]) rescue (raise NotFound, "Cannot find User #{session[:user]}, maybe it got deleted by an Administrator.")
    rescue
      logout_and_redirect_to_login
    else
      redirect_to user_url(session[:user]), :alert => $!
    end
  end

  def redirect_to_list_users(message)
    flash = message
    @users = User.list
    render :index
  end

end
