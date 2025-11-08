module ApplicationHelper
  SECONDS_IN_MINUTE = 60
  SECONDS_IN_HOUR = 3600
  SECONDS_IN_DAY = 86400
  SECONDS_IN_MONTH = 2592000 # 30日

  # 日本語で経過時間を表示（1ヶ月以内）または日付表示（1ヶ月以上前）
  # @param time [Time, ActiveSupport::TimeWithZone] 表示する時刻
  # @return [String] 日本語でフォーマットされた時刻表示（例：「5分前」「2024年10月15日」）
  def japanese_time_ago(time)
    seconds = (Time.current - time).to_i

    if seconds < SECONDS_IN_MONTH
      relative_time_display(seconds)
    else
      time.strftime("%Y年%m月%d日")
    end
  end

  private

  # 相対時間を日本語で表示
  def relative_time_display(seconds)
    case seconds
    when 0...SECONDS_IN_MINUTE
      "#{seconds}秒前"
    when SECONDS_IN_MINUTE...SECONDS_IN_HOUR
      "#{seconds / SECONDS_IN_MINUTE}分前"
    when SECONDS_IN_HOUR...SECONDS_IN_DAY
      "#{seconds / SECONDS_IN_HOUR}時間前"
    else
      "#{seconds / SECONDS_IN_DAY}日前"
    end
  end
end
