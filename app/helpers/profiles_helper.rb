# frozen_string_literal: true

module ProfilesHelper
  # プロフィールタブのリンクを生成
  def profile_tab_link(path, icon, label, is_active:)
    link_to path, class: "nav-link profile-tab-link #{'active' if is_active}", data: { turbo_frame: "profile_content", turbo_action: "advance" } do
      concat content_tag(:i, "", class: "#{icon} me-2")
      concat label
    end
  end

  # commit logタブのパスを取得
  def commit_log_tab_path
    params[:id] ? user_profile_path(params[:id]) : profile_path
  end

  # commit logタブがアクティブかどうか
  def commit_log_tab_active?
    path = commit_log_tab_path
    current_page?(path)
  end

  # Starタブのパスを取得
  def stars_tab_path
    profile_likes_path
  end

  # Starタブがアクティブかどうか
  def stars_tab_active?
    path = stars_tab_path
    current_page?(path)
  end
end
