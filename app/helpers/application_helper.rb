module ApplicationHelper
  include ChefServerWebui::Helpers

  ROLE_STR = "role"
  RECIPE_STR = "recipe"

  def class_for_run_list_item(item)
    case item.type.to_s
    when ROLE_STR
      'ui-state-highlight'
    when RECIPE_STR
      'ui-state-default'
    else
      raise ArgumentError, "Cannot generate UI class for #{item.inspect}"
    end
  end

  def display_run_list_item(item)
    case item.type.to_s
    when ROLE_STR
      item.name
    when RECIPE_STR
      # webui not sophisticated enough for versioned recipes
      # "#{item.name}@#{item.version}"
      item.name
    else
      raise ArgumentError, "can't generate display string for #{item.inspect}"
    end
  end

  def nav_link_item(title, dest)
    name = title.gsub(/ /, "").downcase
    klass = controller_name == name ? 'class="active"' : ""
    link = link_to(title, url_for(dest))
    raw("<li #{klass}>#{link}</li>")
  end

  def convert_newline_to_br(string)
    string.to_s.gsub(/\n/, '<br />') unless string.nil?
  end

  def clippy(text, bgcolor='#F4F4F6')
    # Ensure text is properly escaped
    text = Rack::Utils.escape(text)
    html = <<-EOF
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              class="clippy" >
      <param name="movie" value="#{asset_path("clippy.swf")}"/>
      <param name="allowScriptAccess" value="sameDomain" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="text=#{text}">
      <param name="bgcolor" value="#{bgcolor}">
      <embed src="#{asset_path("clippy.swf")}"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="sameDomain"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="text=#{text}"
             bgcolor="#{bgcolor}"
      />
      </object>
    EOF
    raw(html)
  end
end
