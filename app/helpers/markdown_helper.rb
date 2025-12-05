module MarkdownHelper
  require "redcarpet"

  def markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      safe_links_only: true,
      with_toc_data: true,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" }
    )

    options = {
      autolink: true,
      fenced_code_blocks: true,
      tables: true,
      strikethrough: true,
      lax_spacing: true,
      no_intra_emphasis: true,
      space_after_headers: true
    }

    markdown = Redcarpet::Markdown.new(renderer, options)
    html = markdown.render(text)

    allowed_tags = %w[h1 h2 h3 h4 h5 h6 p br strong em del ul ol li a blockquote code pre table thead tbody tr th td hr]
    allowed_attributes = { "a" => %w[href target rel] }

    sanitize(html, tags: allowed_tags, attributes: allowed_attributes).html_safe
  end
end
