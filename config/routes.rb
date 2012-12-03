#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008-2010 Opscode, Inc.
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

ChefServerWebui::Application.routes.draw do
  resources :nodes, :id => /[^\/]+/
  match "/nodes/_environments/:environment_id", :to => "nodes#index", :as => :nodes_by_environment

  resources :clients, :id => /[^\/]+/
  resources :roles

  resources :environments do
    match "/recipes", :only => :get, :to => "environments#list_recipes"
    match "/cookbooks", :to => "environments#list_cookbooks", :as => :cookbooks, :only => :get
    match "/nodes", :to => "environments#list_nodes", :as => :nodes, :only => :get
    match "/select", :to => "environments#select_environment", :as => :select, :only => :get
  end

  # match '/environments/create' :to => "environments#create", :as => :environments_create

  match "/status", :to => "status#index", :as => :status, :only => :get

  resources :searches, :path => "search", :controller => "search", :only => [:index, :show]

  match "/cookbooks/_attribute_files", :to => "cookbooks#attribute_files"
  match "/cookbooks/_recipe_files", :to => "cookbooks#recipe_files"
  match "/cookbooks/_definition_files", :to => "cookbooks#definition_files"
  match "/cookbooks/_library_files", :to => "cookbooks#library_files"
  match "/cookbooks/_environments/:environment_id", :to => "cookbooks#index", :as => :cookbooks_by_environment

  match "/cookbooks/:cookbook_id", :cookbook_id => /[\w\.]+/, :only => :get, :to => "cookbooks#cb_versions"
  match "/cookbooks/:cookbook_id/:cb_version", :cb_version => /[\w\.]+/, :only => :get, :to => "cookbooks#show", :as => :cookbook_version
  resources :cookbooks

  resources :clients

  resources :databags do
    resources :databag_items, :except => [:index]
  end

  resources :users do
    member do
      get 'logout'
      get 'complete'
    end
    collection do
      get 'login'
      post 'login_exec'
    end
  end

  match '/', :to => 'nodes#index', :as => :top
end
