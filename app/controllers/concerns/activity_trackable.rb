# frozen_string_literal: true

# アクティビティトラッキング機能を提供するConcern
#
# ユーザーのアクティビティ（投稿・ES更新）を集計し、
# 連続記録、週間/月間進捗、実績フラグを計算します。
module ActivityTrackable
  extend ActiveSupport::Concern

  # ゴール設定（直近の期間内での活動日数）
  WEEKLY_GOAL = 3
  MONTHLY_GOAL = 10
  WEEKLY_DAYS = 7
  MONTHLY_DAYS = 30

  # アクティビティサマリーを準備
  def prepare_activity_summary(counts_by_day)
    active_dates = extract_active_dates(counts_by_day)

    @activity_summary = {
      current_streak: calculate_current_streak(active_dates),
      weekly_active_days: count_active_days_in_range(active_dates, WEEKLY_DAYS),
      monthly_active_days: count_active_days_in_range(active_dates, MONTHLY_DAYS),
      weekly_goal: WEEKLY_GOAL,
      monthly_goal: MONTHLY_GOAL,
      weekly_progress: calculate_progress_percentage(
        count_active_days_in_range(active_dates, WEEKLY_DAYS),
        WEEKLY_GOAL
      ),
      monthly_progress: calculate_progress_percentage(
        count_active_days_in_range(active_dates, MONTHLY_DAYS),
        MONTHLY_GOAL
      )
    }

    @achievement_flags = calculate_achievement_flags
    @achievement_history = calculate_achievement_history
  end

  private

  # アクティブな日付のリストを抽出
  def extract_active_dates(counts_by_day)
    counts_by_day.map do |date, count|
      Date.parse(date) if count.to_i.positive?
    end.compact
  end

  # 現在の連続記録日数を計算
  def calculate_current_streak(active_dates)
    active_date_map = active_dates.index_with(true)
    today = Date.current
    current_streak = 0
    cursor = today

    while active_date_map[cursor]
      current_streak += 1
      cursor -= 1
    end

    current_streak
  end

  # 指定期間内のアクティブ日数をカウント
  def count_active_days_in_range(active_dates, days)
    today = Date.current
    range_start = today - (days - 1)

    active_dates.count { |date| date >= range_start && date <= today }
  end

  # 進捗パーセンテージを計算
  def calculate_progress_percentage(active_days, goal)
    return 0 if goal.zero?

    percentage = ((active_days.to_f / goal) * 100).round
    [percentage, 100].min
  end

  # 実績フラグを計算
  def calculate_achievement_flags
    {
      first_post: @user.posts.exists?,
      first_follow: @user.active_follows.exists?,
      first_es_public: @user.entry_sheets.publicly_visible.exists?,
      first_review_request: @user.posts.joins(:tags).where(tags: { name: "ESレビュー" }).exists?
    }
  end

  # 実績の達成履歴（初回達成日時）を取得
  def calculate_achievement_history
    {
      first_post: @user.posts.minimum(:created_at),
      first_follow: @user.active_follows.minimum(:created_at),
      first_es_public: @user.entry_sheets.publicly_visible.minimum(:updated_at),
      first_review_request: @user.posts.joins(:tags).where(tags: { name: "ESレビュー" }).minimum(:created_at)
    }
  end
end
