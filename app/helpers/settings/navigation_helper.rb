module Settings
  module NavigationHelper
    # Build a sidebar link that applies the active class when the current tab matches.
    def settings_nav_link(label, path, icon:, active: current_page?(path))
      classes = %w[list-group-item list-group-item-action]
      classes << "active" if active

      link_to path, class: classes.join(" ") do
        safe_join([ content_tag(:i, "", class: "#{icon} me-2"), label ])
      end
    end
  end
end
