class PostDecorator
  include ERB::Util

  URL_PATTERN = /(https?:\/\/[^\s]+)/

  attr_reader :post

  # 明示的に委譲するメソッドのみを許可
  delegate :content, :tags, :association, to: :post

  def initialize(post)
    @post = post
  end

  def highlighted_content
    return "" if content.blank?

    escaped = html_escape(content)
    highlighted = highlight_hashtags(escaped)
    highlighted = highlight_urls(highlighted)
    format_text(highlighted).html_safe
  end

  private

  def highlight_hashtags(text)
    tags_by_name = tags.index_by(&:name)

    text.gsub(Tag::HASHTAG_REGEX) do
      match = Regexp.last_match
      full_match = match[0]
      tag_name = match[1]
      matching_tag = tags_by_name[tag_name]
      space = full_match[/^[\s\u3000]/] || ""

      if matching_tag
        "#{space}<a href=\"/tags/#{matching_tag.id}\" class=\"hashtag-highlight\" data-turbo-frame=\"_top\">##{tag_name}</a>"
      else
        "#{space}<span class=\"hashtag-highlight\">##{tag_name}</span>"
      end
    end
  end

  def highlight_urls(text)
    text.gsub(URL_PATTERN) do |url|
      "<a href=\"#{url}\" target=\"_blank\" rel=\"noopener noreferrer\" class=\"url-highlight\">#{url}</a>"
    end
  end

  def format_text(text)
    text = text.gsub(/\r\n?/, "\n")

    paragraphs = text.split(/\n\n+/).map do |paragraph|
      paragraph.gsub(/\n/, "<br />")
    end

    paragraphs.map { |p| "<p>#{p}</p>" }.join("\n")
  end
end
