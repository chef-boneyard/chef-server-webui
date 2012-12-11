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

module CookbooksHelper

  def more_versions_link(cookbook)
    link_to("+", "JavaScript:void(0);",
            :title => "show other versions of #{cookbook}",
            :data => cookbook,
            :class => "cookbook_version_toggle")
  end

  def all_versions_link(cookbook)
    link_to("show all versions...", "JavaScript:void(0);",
            :class => "show_all",
            :id => "#{cookbook}_show_all",
            :data => cookbook,
            :title => "show all versions of #{cookbook}")
  end

  def cookbook_link(version)
    cookbook_version_path(version, @cookbook_id)
  end
end
