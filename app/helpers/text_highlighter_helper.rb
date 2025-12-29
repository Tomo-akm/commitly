module TextHighlighterHelper
  URL_PATTERN = /(https?:\/\/[^\s<>\"]+?)(?=[<>\".,;!?)]*(?:\s|$))/

  def linkify_urls(text, html_options = {})
    return "" if text.blank?

    linked = TextHighlighterHelper.linkify_urls_text(text)
    simple_format(linked, html_options, sanitize: false)
  end

  def self.linkify_urls_text(text, css_class: "url-highlight", escape: true)
    return "" if text.blank?

    source = escape ? ERB::Util.html_escape(text) : text
    source.gsub(URL_PATTERN) do |url|
      "<a href=\"#{url}\" target=\"_blank\" rel=\"noopener noreferrer\" class=\"#{css_class}\">#{url}</a>"
    end
  end
end
