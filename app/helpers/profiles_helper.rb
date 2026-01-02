# frozen_string_literal: true

module ProfilesHelper
  ActivitySummary = Struct.new(
    :current_streak,
    :weekly_active_days,
    :weekly_goal,
    :weekly_progress,
    :monthly_active_days,
    :monthly_goal,
    :monthly_progress,
    keyword_init: true
  )

  def activity_summary(summary)
    data = summary || {}
    ActivitySummary.new(
      current_streak: data[:current_streak].to_i,
      weekly_active_days: data[:weekly_active_days].to_i,
      weekly_goal: data[:weekly_goal].to_i,
      weekly_progress: data[:weekly_progress].to_i,
      monthly_active_days: data[:monthly_active_days].to_i,
      monthly_goal: data[:monthly_goal].to_i,
      monthly_progress: data[:monthly_progress].to_i
    )
  end

  # プロフィールタブのリンクを生成
  def profile_tab_link(path, icon, label, is_active:)
    link_to path, class: "nav-link profile-tab-link #{'active' if is_active}", data: { turbo_frame: "profile_content", turbo_action: "advance" } do
      concat content_tag(:i, "", class: "#{icon} me-2")
      concat label
    end
  end

  # commit logタブのパスを取得
  def commit_log_tab_path
    if params[:account_id]
      user_profile_path(params[:account_id])
    elsif current_user
      user_profile_path(current_user.account_id)
    else
      root_path
    end
  end

  # commit logタブがアクティブかどうか
  def commit_log_tab_active?
    path = commit_log_tab_path
    current_page?(path)
  end

  # Starタブのパスを取得
  def stars_tab_path
    return root_path unless current_user

    user_profile_likes_path(current_user.account_id)
  end

  # Starタブがアクティブかどうか
  def stars_tab_active?
    path = stars_tab_path
    current_page?(path)
  end

  # 実績の達成日をフォーマット
  def format_achievement_date(date)
    date ? date.strftime("%Y/%m/%d") : "未達成"
  end
end
