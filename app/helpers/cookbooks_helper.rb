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
