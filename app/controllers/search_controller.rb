#
# Author:: Nuo Yan (<nuo@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/search/query'

class SearchController < ApplicationController

  respond_to :html
  before_filter :require_login

  def index
    @search_indexes = begin
                        client_with_actor.get("search")
                      rescue => e
                        log_and_flash_exception(e, "Could not list search indexes")
                        {}
                      end
  end

  def show
    begin
      query = (params[:q].nil? || params[:q].empty?) ? "*:*" : URI.escape(params[:q], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      response = client_with_actor.get("search/#{params[:id]}?q=#{query}&sort=&start=0&rows=20")
      @results = [ response["rows"], response["start"], response["total"] ]
      @type = if params[:id].to_s == "node" || params[:id].to_s == "role" || params[:id].to_s == "client" || params[:id].to_s == "environment"
                params[:id]
              else
                "databag"
              end
      @results = @results - @results.last(2)
      @results.each do |result|
        result.delete(nil)
      end
      @results
    rescue => e
      log_and_flash_exception(e, "Unable to find the #{params[:id]}")
      redirect_to :searches
    end
  end

end
