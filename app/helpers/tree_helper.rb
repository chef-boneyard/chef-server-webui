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

module TreeHelper
  def build_tree(name, node)
    html = "<table id='#{name}' class='tree table'>"
    html << "<tr><th class='first'>Attribute</th><th class='last'>Value</th></tr>"
    count = 0
    parent = 0
    append_tree(name, html, node, count, parent)
    html << "</table>"
    raw(html)
  end

  def append_tree(name, html, node, count, parent)
    to_do = node
    #to_do = node.kind_of?(Chef::Node) ? node.attribute : node
    logger.debug("I have #{to_do.inspect}")
    to_do.sort{ |a,b| a[0] <=> b[0] }.each do |key, value|
      logger.debug("I am #{key.inspect} #{value.inspect}")
      to_send = Array.new
      count += 1
      is_parent = false
      local_html = ""
      local_html << "<tr id='#{name}-#{count}' class='collapsed #{name}"
      if parent != 0
        local_html << " child-of-#{name}-#{parent}' style='display: none;'>"
      else
        local_html << "'>"
      end
      local_html << "<td class='table-key'><span toggle='#{name}-#{count}'/>#{key}</td>"
      case value
      when Hash
        is_parent = true
        local_html << "<td></td>"
        p = count
        to_send << Proc.new { append_tree(name, html, value, count, p) }
      when Array
        is_parent = true
        local_html << "<td></td>"
        as_hash = {}
        value.each_index { |i| as_hash[i] = value[i] }
        p = count
        to_send << Proc.new { append_tree(name, html, as_hash, count, p) }
      else
        local_html << "<td><div class='json-attr'>#{value}</div></td>"
      end
      local_html << "</tr>"
      local_html.sub!(/class='collapsed/, 'class=\'collapsed parent') if is_parent
      local_html.sub!(/<span/, "<span class='expander'") if is_parent
      html << local_html
      to_send.each { |s| count = s.call }
      count += to_send.length
    end
    count
  end
end
