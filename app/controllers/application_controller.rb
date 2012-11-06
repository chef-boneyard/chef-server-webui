class ApplicationController < ActionController::Base
  include SessionHelper
  include ChefServerWebui::ApiClientHelper
  include Chef::Mixin::Checksum

  # Make the logged-in user globally available in the current thread using the
  # Thread.current hash.  We use an around filter to ensure the thread local
  # variable is cleaned up before being used if this thread is recycled.
  around_filter do |controller, action|
    if current_user = controller.current_user
       Thread.current[:current_user_id] = controller.current_user.name
    end
    begin
      action.call
    ensure
      Thread.current[:current_user_id] = nil
    end
  end

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

  end

  end

  def load_environments
    @environments = client_with_actor.get("environments").keys.sort
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

  def syntax_highlight(file_url)
    Chef::Log.debug("fetching file from '#{file_url}' for highlighting")
    highlighted_file = nil
    client_with_actor.fetch(file_url) do |tempfile|
      tokens = CodeRay.scan_file(tempfile.path, :ruby)
      highlighted_file = CodeRay.encode_tokens(tokens, :span)
    end
    highlighted_file
  end

  def show_plain_file(file_url)
    Chef::Log.debug("fetching file from '#{file_url}' for highlighting")
    client_with_actor.fetch(file_url) do |tempfile|
      if binary?(tempfile.path)
        return "Binary file not shown"
      elsif ((File.size(tempfile.path) / (1048576)) > 5)
        return "File too large to display"
      else
        return IO.read(tempfile.path)
      end
    end
  end

  def binary?(file)
    s = (File.read(file, File.stat(file).blksize) || "")
    s.empty? || ( s.count( "^ -~", "^\r\n" ).fdiv(s.size) > 0.3 || s.index( "\x00" ))
  end

  # taken from ActiveRecord::ConnectionAdapters::Column
  def value_to_boolean(value)
    if value.is_a?(String) && value.blank?
      nil
    else
      [true, 1, '1', 't', 'T', 'true', 'TRUE'].include?(value)
    end
  end

  def list_available_recipes_for(environment)
    client_with_actor.get("environments/#{environment}/recipes").sort!
  end

  def format_exception(exception)
    require 'pp'
    pretty_params = StringIO.new
    PP.pp({:request_params => params}, pretty_params)
    "#{exception.class.name}: #{exception.message}\n#{pretty_params.string}\n#{exception.backtrace.join("\n")}"
  end

  def conflict?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /409/
  end

  def forbidden?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /403/
  end

  def not_found?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /404/
  end

  def bad_request?(exception)
    exception.kind_of?(Net::HTTPServerException) && exception.message =~ /400/
  end
end
