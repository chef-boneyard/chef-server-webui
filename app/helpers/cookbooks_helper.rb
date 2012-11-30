module CookbooksHelper
  include ChefServerWebui::ApiClientHelper

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
    show_specific_version_cookbook_path(version, @cookbook_id)
  end

  def cookbook_parts
    Chef::CookbookVersion::COOKBOOK_SEGMENTS.map do |p|
      part = p.to_s
      case part
      when "files"
        [part, "plain"]
      else
        [part, "ruby"]
      end
    end.sort { |a, b| a[0] <=> b[0] }
  end

  def highlight_content(url, type)
    case type
    when "plain"
      show_plain_file(url)
    else
      begin
        syntax_highlight(url)
      rescue
        logger.error("Error while parsing file #{url}")
        show_plain_file(url)
      end
    end
  end

  def syntax_highlight(file_url)
    logger.debug("fetching file from '#{file_url}' for highlighting")
    highlighted_file = nil
    client_with_actor.fetch(file_url) do |tempfile|
      tokens = CodeRay.scan_file(tempfile.path, :ruby)
      highlighted_file = CodeRay.encode_tokens(tokens, :span)
    end
    highlighted_file
  end

  def show_plain_file(file_url)
    logger.debug("fetching file from '#{file_url}' for highlighting")
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
end
