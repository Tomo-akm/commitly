module ApplicationHelper
  # 日本語で経過時間を表示（1ヶ月以内）または日付表示（1ヶ月以上前）
  # @param time [Time, ActiveSupport::TimeWithZone] 表示する時刻
  # @return [String] 日本語でフォーマットされた時刻表示（例：「5分前」「2024年10月15日」）
  def japanese_time_ago(time)
    seconds = (Time.current - time).to_i

    if seconds < 30.days
      relative_time_display(seconds)
    else
      time.strftime("%Y年%m月%d日")
    end
  end

  def render_right_nav
    return unless content_for?(:right_nav)

    content_tag(:div, class: "app-shell__right") do
      yield
    end
  end

  # 無限スクロール用の次ページパスを生成するLambdaを返す
  def infinite_scroll_next_page_path(context, options = {})
    case context
    when :posts
      ->(page) { posts_path(q: params[:q], page: page) }
    when :tag
      tag = options[:tag]
      ->(page) { tag_path(tag, q: params[:q], page: page) }
    when :user_profile
      user = options[:user]
      ->(page) { user_profile_path(user.account_id, page: page) }
    when :likes
      user = options[:user]
      ->(page) { likes_user_profile_path(user.account_id, page: page) }
    else
      raise ArgumentError, "Unknown infinite scroll context: #{context.inspect} (expected :posts, :tag, :user_profile, or :likes)"
    end
  end

  private

  # 相対時間を日本語で表示
  def relative_time_display(seconds)
    case seconds
    when 0...1.minute
      "#{seconds}秒前"
    when 1.minute...1.hour
      "#{seconds / 1.minute}分前"
    when 1.hour...1.day
      "#{seconds / 1.hour}時間前"
    else
      "#{seconds / 1.day}日前"
    end
  end
end
