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
