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

module SessionHelper

  # The logged_in? method simply returns true if the user is logged
  # in and false otherwise. It does this by "booleanizing" the
  # current_user method we created previously using a double ! operator.
  # Note that this is not common in Ruby and is discouraged unless you
  # really mean to convert something into true or false.
  def logged_in?
    !!current_user
  end

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    @_current_user ||= session[:current_user_id] &&
      User.load(session[:current_user_id])
  end

  def cleanup_session
    [:current_user_level, :environment].each { |n| session.delete(n) }
    @_current_user = session[:current_user_id] = nil
  end

  def logout_and_redirect_to_login
    cleanup_session
    @user = User.new
    redirect_to login_users_url, :alert => $!
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.url
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    loc = session[:return_to] || default
    session[:return_to] = nil
    redirect_to loc
  end

  #whether or not the user should be able to edit a user's admin status
  def can_edit_admin?(user)
    # only admins can edit flag
    if current_user.admin?
      # an admin can edit other users flag
      if user != current_user.name
        true
      # an admin can edit their own flag if they are not the last admin
      elsif current_user.last_admin?
        false
      end
    else
      false
    end
  end
end
