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
  layout 'login', :only => :login
  respond_to :html

  before_filter :require_login, :except => [:login, :login_exec, :complete]

  # Ensure only admins try and create/delete users
  before_filter :except => [:login, :login_exec, :complete, :show, :edit,
                            :update, :logout] do |controller|

    require_admin(self)
  end

  # Ensure non-admin users are only taking action on themselves
  before_filter :only => [:update, :destroy] do |controller|
    unless (current_user.admin? || (params[:id] == current_user.name))
      require_admin(self)
    end
  end

  # Ensure the last admin doesn't try and delete themselves
  before_filter :only => :destroy do |controller|
    if params[:id] == current_user.name && (current_user.last_admin?)
      raise HTTPStatus::Forbidden, "The last admin user cannot be deleted"
    end
  end

  # List users, only if the user is admin.
  def index
    @users = User.list
  rescue => e
    log_and_flash_exception(e)
    set_user_and_redirect
  end

  # Edit user. Admin can edit everyone, non-admin user can only edit itself.
  def edit
    @user = User.load(params[:id])
  rescue => e
    log_and_flash_exception(e)
    set_user_and_redirect
  end

  # Show the details of a user. If the user is not admin, only able to show itself; otherwise able to show everyone
  def show
    @user = User.load(params[:id])
  rescue => e
    log_and_flash_exception(e)
    set_user_and_redirect
  end

  # PUT to /users/:id/update
  def update
    @user = User.load(params[:id])
    @user.assign_attributes(params[:user])

    if @user.name == current_user.name && !@user.admin?
      session[:current_user_level] = :user
    end

    if @user.valid?(:update)
      @user.save
      notice = "Updated user #{@user.name}."
      if @user.regenerate_private_key?
        notice << " Please copy the following private key as the users's private key."
      end
      flash.now[:notice] = notice
      render :show
    else
      render :edit
    end
  rescue => e
    log_and_flash_exception(e, "Could not update user #{@user.name}.")
    render :edit
  end

  def new
    @user = User.new
  rescue => e
    log_and_flash_exception(e)
    set_user_and_redirect
  end

  def create
    @user = User.new(params[:user])
    if @user.valid?(:create)
      @user.create
      flash.now[:notice] = "Created user #{@user.name}. Please copy the following private key as the users's private key."
      render :show
    else
      render :new
    end
  rescue => e
    log_and_flash_exception(e, "Could not create user")
    !current_user.admin? ? set_user_and_redirect : (render :new)
  end

  def login
    if current_user
      redirect_to :nodes, :flash => { :warning => "You've already logged in with user #{current_user.name}" }
    else
      @user = User.new
    end
  end

  def login_exec
    if user = User.authenticate(params[:name], params[:password])
      session[:current_user_id] = user.name
      session[:current_user_level] = (user.admin? ? :admin : :user)
      # Nag the admin to change the default password
      if (user.name == ChefServerWebui::Application.config.admin_user_name &&
            User.authenticate(ChefServerWebui::Application.config.admin_user_name,
                              ChefServerWebui::Application.config.admin_default_password))
        redirect_to(edit_user_url(user), :flash => { :warning => "Please change the default password" })
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

    if params[:id] == current_user.name
      logout
    else
      redirect_to :users, :notice => "User #{params[:id]} deleted successfully."
    end
  rescue => e
    log_and_flash_exception(e)
    !current_user.admin? ? (set_user_and_redirect) : (redirect_to :users)
  end

  private

  def set_user_and_redirect
    if @user.name = current_user.name
      redirect_to user_url(current_user.name), :alert => $!
    else
      logout_and_redirect_to_login
    end
  end

end
