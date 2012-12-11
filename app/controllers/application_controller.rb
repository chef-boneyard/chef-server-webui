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

class ApplicationController < ActionController::Base
  include SessionHelper
  include ChefServerWebui::ApiClientHelper
  include ChefServerWebui::Helpers

  # Make the logged-in user globally available in the current thread using the
  # Thread.current hash.  We use an around filter to ensure the thread local
  # variable is cleaned up before being used if this thread is recycled.
  around_filter do |controller, action|
    if current_user = controller.current_user
       Thread.current[:current_user_id] = current_user.name
    end
    begin
      action.call
    ensure
      Thread.current[:current_user_id] = nil
    end
  end

  # Handle all uncaught exceptions
  rescue_from Exception do |e|
    exception = if e.kind_of?(HTTPStatus::Base)
                  e
                # convert Net::HTTPServerException into HTTPStatus::*
                elsif e.kind_of?(Net::HTTPServerException)
                  case e.response.code
                  when /400/; HTTPStatus::BadRequest.new(e.message)
                  when /401/; HTTPStatus::Unauthorized.new(e.message)
                  when /403/; HTTPStatus::Forbidden.new(e.message)
                  when /404/; HTTPStatus::NotFound.new(e.message)
                  else
                    HTTPStatus::InternalServerError.new(error_message)
                  end
                # treat everything else as a 500
                else
                  log_and_flash_exception(e)
                  if error_message = flash[:error]
                    flash.delete(:error)
                  end
                  HTTPStatus::InternalServerError.new(error_message)
                end
    http_status_exception(exception)
  end

  # load environments if we are logged in
  before_filter {|controller| load_environments if logged_in?}

  #############################################################################
  # Filters
  #############################################################################

  def require_login
    unless logged_in?
      self.store_location
      redirect_to login_users_url, :notice => "You don't have access to that, please login."
    end
  end

  def require_admin(calling_controller=nil)
    unless current_user.admin?
      msg = "You are not authorized to perform this action!"
      if calling_controller
        resource_name = calling_controller.class.to_s.underscore.split('_').first
        action_name = case calling_controller.action_name
                      when "new"; "create"
                      when "index"; "list"
                      else calling_controller.action_name; end
        msg = "You are not authorized to #{action_name} #{resource_name}!"
      end
      raise HTTPStatus::Unauthorized, msg
    end
  end

  #############################################################################
  # Exception Handling
  #############################################################################

  def format_exception(exception)
    require 'pp'
    pretty_params = StringIO.new
    PP.pp({:request_params => params}, pretty_params)
    "#{exception.class.name}: #{exception.message}\n#{pretty_params.string}\n#{exception.backtrace.join("\n")}"
  end

  def log_and_flash_exception(exception, flash_message=nil)
    logger.error(format_exception(exception))
    flash.now[:error] = if flash_message
      "#{flash_message}: #{exception.message}"
    else
      "ERROR: #{exception.message}"
    end
  end

  #############################################################################
  # Chef Object Helpers
  #############################################################################

  def load_environments
    @environments = client_with_actor.get("environments").keys.sort
  end

  def list_available_recipes_for(environment)
    client_with_actor.get("environments/#{environment}/recipes").sort!
  end

  # Load a cookbook and return a hash with a list of all the files of a
  # given segment (attributes, recipes, definitions, libraries)
  #
  # === Parameters
  # cookbook_id<String>:: The cookbook to load
  # segment<Symbol>:: :attributes, :recipes, :definitions, :libraries
  #
  # === Returns
  # <Hash>:: A hash consisting of the short name of the file in :name, and the full path
  #   to the file in :file.
  def load_cookbook_segment(cookbook_id, segment)
    cookbook = client_with_actor.get("cookbooks/#{cookbook_id}")

    raise HTTPStatus::NotFound unless cookbook

    files_list = segment_files(segment, cookbook)

    files = Hash.new
    files_list.each do |f|
      files[f['name']] = {
        :name => f["name"],
        :file => f["uri"],
      }
    end
    files
  end

  def segment_files(segment, cookbook)
    files_list = nil
    case segment
    when :attributes
      files_list = cookbook["attributes"]
    when :recipes
      files_list = cookbook["recipes"]
    when :definitions
      files_list = cookbook["definitions"]
    when :libraries
      files_list = cookbook["libraries"]
    else
      raise HTTPStatus::Forbidden, "segment must be one of :attributes, :recipes, :definitions or :libraries"
    end
    files_list
  end
end
