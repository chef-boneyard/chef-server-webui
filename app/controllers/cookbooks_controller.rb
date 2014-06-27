#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

require 'chef/cookbook_loader'
require 'chef/cookbook_version'

class CookbooksController < ApplicationController

  respond_to :html
  before_filter :require_login
  before_filter :params_helper

  attr_reader :cookbook_id
  def params_helper
    @cookbook_id = params[:id] || params[:cookbook_id]
  end

  def index
    @cl = fetch_cookbook_versions(6)
    respond_with @cl
  end

  def show
    begin
      all_books = fetch_cookbook_versions("all", :cookbook => cookbook_id)
      @versions = all_books[cookbook_id].map { |v| v["version"] }
      if params[:cb_version] == "_latest"
        redirect_to cookbook_version_url(cookbook_id, @versions.first)
        return
      end
      @version = params[:cb_version]
      if !@versions.include?(@version)
        msg = { :warning => ["Cookbook #{cookbook_id} (#{params[:cb_version]})",
                             "is not available in the #{session[:environment]}",
                             "environment."
                            ].join(" ") }
        redirect_to cookbooks_url, :flash => msg
        return
      end
      cookbook_url = "cookbooks/#{cookbook_id}/#{@version}"
      @cookbook = client_with_actor.get(cookbook_url)

      raise HTTPStatus::NotFound, "Cannot find cookbook #{cookbook_id} (@version)" unless @cookbook

      # don't build the manifest in the view please
      manifest = @cookbook.manifest if @cookbook

      #== cookbook_files
      # a ::Hash of :cookbook_part => files
      #
      # :files: a hash of :filename => hilighted_text
      #
      # i.e.
      # {
      #   "recipes" => {
      #     "default.rb" => "THIS IS MY RUBY FILE HIGHLIGHTED",
      #     "library.rb" => "THIS IS A LIBRARY HIGHLIGHTED"
      #   },
      #   "templates" => {}
      # }
      #
      if manifest
        @cookbook_files = cookbook_parts.inject({}) do |parts, part|
          part_files = manifest[part].inject({}) do |files, file|
            files[file["name"]] = syntax_highlight(file["url"], file["name"])
            files
          end
          parts[part] = part_files
          parts
        end
      end

      respond_with @cookbook
    rescue => e
      log_and_flash_exception(e)
      @cl = {}
      render :index
    end
  end

  # GET /cookbooks/cookbook_id
  # provides :json, for the javascript on the environments web form.
  def cb_versions
    use_envs = session[:environment] && !params[:ignore_environments]
    num_versions = params[:num_versions] || "all"
    all_books = fetch_cookbook_versions(num_versions, :cookbook => cookbook_id,
                                        :use_envs => use_envs)

    respond_to do |format|
      format.html do
        redirect_to cookbook_version_url(:cookbook_id => cookbook_id,
                                          :cb_version => '_latest')
      end
      format.json { render :json => { cookbook_id => all_books[cookbook_id] } }
    end
  end

  def recipe_files
    # node = params.has_key?('node') ? params[:node] : nil
    # @recipe_files = load_all_files(:recipes, node)
    @recipe_files = client_with_actor.get("cookbooks/#{params[:id]}/recipes")
    respond_with @recipe_files
  end

  def attribute_files
    @attribute_files = client_with_actor.get("cookbooks/#{params[:id]}/attributes")
    respond_with @attribute_files
  end

  def definition_files
    @definition_files = client_with_actor.get("cookbooks/#{params[:id]}/definitions")
    respond_with @definition_files
  end

  def library_files
    @lib_files = client_with_actor.get("cookbooks/#{params[:id]}/libraries")
    respond_with @lib_files
  end

  private

  def fetch_cookbook_versions(num_versions, options={})
    opts = { :use_envs => true, :cookbook => nil }.merge(options)
    url = if opts[:use_envs]
            env = session[:environment] || "_default"
            "environments/#{env}/cookbooks"
          else
            "cookbooks"
          end
    # we want to display at most 5 versions, but we ask for 6.  This
    # tells us if we should display a 'show all' button or not.
    url += "/#{opts[:cookbook]}" if opts[:cookbook]
    url += "?num_versions=#{num_versions}"
    begin
      result = client_with_actor.get(url)
      result.inject({}) do |ans, (name, cb)|
        cb["versions"].each do |v|
          v["url"] = cookbook_version_url(:cookbook_id => name,
                                                        :cb_version => v["version"])
        end
        ans[name] = cb["versions"]
        ans
      end
    rescue => e
      log_and_flash_exception(e, $!)
      {}
    end
  end

  #
  # the following section is used for rendering cookbook file contents
  #

  BINARY_EXTENSIONS = ['.gz', '.zip', '.tar', '.bz2', '.so',
                       '.jpg', '.gif', '.png', '.gd2'].inject({}) do |h, ext|
    h[ext] = true
    h
  end

  MAX_FILE_SIZE_MB = 1

  def cookbook_parts
    Chef::CookbookVersion::COOKBOOK_SEGMENTS.map do |p|
      p.to_s
    end.sort
  end

  # Return a string suitable for <pre></pre> containing contents of
  # file_url.
  #
  # Known formats (by file extension) are syntax highlighted using
  # CodeRay.  We attempt to detect and avoid displaying binary
  # files.
  #
  def syntax_highlight(file_url, file_name)
    highlighted_file = nil
    lang = CodeRay::FileType[file_name]

    # Due to a bug in Chef client
    # (https://tickets.opscode.com/browse/CHEF-3058), we need to manually
    # override the Accept header here.
    old_custom_headers = Chef::Config[:custom_http_headers]
    Chef::Config[:custom_http_headers] = { 'Accept' => '*/*' }

    if lang
      logger.debug("fetching file from '#{file_url}' for highlighting")

      file = client_with_actor.get(file_url)
      tokens = CodeRay.scan(file.force_encoding('utf-8'), lang)
      highlighted_file = CodeRay.encode_tokens(tokens, :span)
      highlighted_file.html_safe
    else
      if binary_extension?(file_name)
        "Binary file not shown: binary file extension".html_safe
      else
        show_plain_file(file_url)
      end
    end
  rescue Encoding::UndefinedConversionError => e
    "Encoding error converting #{e.error_char.dump} from " \
    "#{e.source_encoding_name} to #{e.destination_encoding_name}".html_safe
  ensure
    Chef::Config[:custom_http_headers] = old_custom_headers
  end

  def show_plain_file(file_url)
    file = client_with_actor.get(file_url)
    logger.debug("fetching file from '#{file_url}' for plain-lighting")
    file_size = file.length
    if file_size == 0
      "Zero length file not shown".html_safe
    elsif binary_contents?(file)
      "Binary file not shown: found null byte or more than 30% " \
      "non-printable characters".html_safe
    elsif (file_size / (1024*1024) > MAX_FILE_SIZE_MB)
      "File too large to display".html_safe
    else
      file
    end
  end

  def binary_extension?(file_name)
    BINARY_EXTENSIONS.has_key?(::File.extname(file_name))
  end

  def binary_contents?(s)
    return true if !s || s.empty?   # empty files might as well be binary
    return true if s.index("\x00")
    # otherwise, binary if more than 30% non-printable characters
    non_printable = s.gsub(/[[:print:]]/, '')
    non_printable.size.fdiv(s.size) > 0.30
  end
end
