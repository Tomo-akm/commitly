# frozen_string_literal: true

# アクティビティトラッキング機能を提供するConcern
#
# ユーザーのアクティビティ（投稿・ES更新・テンプレ更新）を集計し、
# 連続記録、週間/月間進捗、実績フラグを計算します。
#
module ActivityTrackable
  extend ActiveSupport::Concern

  # ゴール設定（直近の期間内での活動日数）
  WEEKLY_GOAL = 3
  MONTHLY_GOAL = 10
  STREAK_LEVELS = [ 7, 14, 30 ].freeze
  WEEKLY_GOAL_LEVELS = [ 1, 2, 3 ].freeze
  MONTHLY_GOAL_LEVELS = [ 1, 2, 3 ].freeze
  ES_PUBLIC_LEVELS = [ 3, 5, 10 ].freeze
  REVIEW_REQUEST_LEVELS = [ 3, 5, 10 ].freeze
  MUTUAL_FOLLOW_LEVELS = [ 5, 10, 20 ].freeze
  TEMPLATE_LEVELS = [ 3, 5, 7 ].freeze
  COMPANY_PROGRESS_LEVELS = [ 3, 5, 7 ].freeze

  # アクティビティサマリーを作成
  #
  # @param counts_by_day [Hash] 日付文字列をキー、活動回数を値とするハッシュ
  #   例: { "2024-01-01" => 2, "2024-01-02" => 1 }
  # @return [Hash] 集計済みアクティビティ情報
  def activity_summary_from_counts(counts_by_day)
    active_dates = extract_active_dates(counts_by_day)
    today = Date.current
    weekly_range = today.beginning_of_week..today.end_of_week
    monthly_range = today.beginning_of_month..today.end_of_month
    weekly_active_days = count_active_days_in_range(active_dates, weekly_range)
    monthly_active_days = count_active_days_in_range(active_dates, monthly_range)

    {
      current_streak: calculate_current_streak(active_dates),
      weekly_active_days: weekly_active_days,
      monthly_active_days: monthly_active_days,
      weekly_goal: WEEKLY_GOAL,
      monthly_goal: MONTHLY_GOAL,
      weekly_progress: calculate_progress_percentage(
        weekly_active_days,
        WEEKLY_GOAL
      ),
      monthly_progress: calculate_progress_percentage(
        monthly_active_days,
        MONTHLY_GOAL
      )
    }
  end

  # 実績フラグを計算
  #
  # @return [Hash] 実績キーをキー、達成状況（true/false）を値とするハッシュ
  def achievement_flags
    achievement_snapshot[:flags]
  end

  # 実績の達成履歴（初回達成日時）を取得
  #
  # @return [Hash] 実績キーをキー、達成日時を値とするハッシュ
  def achievement_history
    achievement_snapshot[:history]
  end

  private

  # アクティブな日付のリストを抽出
  def extract_active_dates(counts_by_day)
    counts_by_day.map do |date, count|
      next unless count.to_i.positive?

      begin
        Date.strptime(date.to_s, "%Y-%m-%d")
      rescue ArgumentError, TypeError
        nil
      end
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
  def count_active_days_in_range(active_dates, range)
    active_dates.count { |date| range.cover?(date) }
  end

  # 進捗パーセンテージを計算
  def calculate_progress_percentage(active_days, goal)
    return 0 if goal.zero?

    percentage = ((active_days.to_f / goal) * 100).round
    [ percentage, 100 ].min
  end

  def achievement_snapshot
    @achievement_snapshot ||= begin
      computed_history = compute_achievement_history
      persist_achievements(computed_history)

      records = user_achievements.reload.index_by { |record| record.achievement_key.to_sym }
      flags = {}
      history = {}
      Achievement.all.each do |achievement|
        record = records[achievement.key]
        flags[achievement.key] = record.present?
        history[achievement.key] = record&.achieved_at
      end

      { flags: flags, history: history }
    end
  end

  def compute_achievement_history
    history = {}

    history[:first_post] = posts.minimum(:created_at)
    history[:first_follow] = active_follows.minimum(:created_at)

    public_es_scope = entry_sheets.where.not(shared_at: nil)
    public_es_thresholds = ([ 1 ] + ES_PUBLIC_LEVELS).uniq.sort
    public_es_dates = threshold_dates_from_scope(public_es_scope, :shared_at, public_es_thresholds)
    history[:first_es_public] = public_es_dates[1]
    ES_PUBLIC_LEVELS.each do |level|
      history[:"es_public_#{level}"] = public_es_dates[level]
    end

    review_scope = posts.top_level.joins(:tags).where(tags: { name: "ESレビュー" })
    review_thresholds = ([ 1 ] + REVIEW_REQUEST_LEVELS).uniq.sort
    review_dates = threshold_dates_from_scope(review_scope, :created_at, review_thresholds)
    history[:first_review_request] = review_dates[1]
    REVIEW_REQUEST_LEVELS.each do |level|
      history[:"review_request_#{level}"] = review_dates[level]
    end

    streak_dates = streak_achieved_dates(STREAK_LEVELS)
    STREAK_LEVELS.each do |level|
      history[:"streak_#{level}"] = streak_dates[level]
    end

    weekly_dates = threshold_dates_from_occurrences(weekly_achievement_dates, WEEKLY_GOAL_LEVELS)
    WEEKLY_GOAL_LEVELS.each do |level|
      history[:"weekly_goal_#{level}"] = weekly_dates[level]
    end

    monthly_dates = threshold_dates_from_occurrences(monthly_achievement_dates, MONTHLY_GOAL_LEVELS)
    MONTHLY_GOAL_LEVELS.each do |level|
      history[:"monthly_goal_#{level}"] = monthly_dates[level]
    end

    template_dates = threshold_dates_from_scope(entry_sheet_item_templates, :created_at, TEMPLATE_LEVELS)
    TEMPLATE_LEVELS.each do |level|
      history[:"template_#{level}"] = template_dates[level]
    end

    mutual_follow_dates = threshold_dates_from_occurrences(mutual_follow_timestamps, MUTUAL_FOLLOW_LEVELS)
    MUTUAL_FOLLOW_LEVELS.each do |level|
      history[:"mutual_follow_#{level}"] = mutual_follow_dates[level]
    end

    company_progress_dates = threshold_dates_from_occurrences(company_progress_timestamps, COMPANY_PROGRESS_LEVELS)
    COMPANY_PROGRESS_LEVELS.each do |level|
      history[:"company_progress_#{level}"] = company_progress_dates[level]
    end

    history
  end

  def persist_achievements(history)
    existing_keys = user_achievements.pluck(:achievement_key).index_with(true)
    history.each do |key, achieved_at|
      next if achieved_at.blank?

      key_str = key.to_s
      next if existing_keys[key_str]

      user_achievements.create!(
        achievement_key: key_str,
        achieved_at: normalize_achieved_at(achieved_at)
      )
      existing_keys[key_str] = true
    end
  end

  def normalize_achieved_at(value)
    return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
    return value.end_of_day if value.is_a?(Date)

    value
  end

  def activity_counts_by_day
    @activity_counts_by_day ||= begin
      start_at = [
        posts.minimum(:created_at),
        entry_sheets.minimum(:updated_at),
        entry_sheet_item_templates.minimum(:updated_at)
      ].compact.min
      start_date = (start_at || Date.current).to_date
      range = start_date..Date.current

      counts = Hash.new(0)
      posts.group_by_day(:created_at, range: range, format: "%Y-%m-%d", time_zone: Time.zone).count.each do |date, count|
        counts[date] += count
      end
      entry_sheets.group_by_day(:updated_at, range: range, format: "%Y-%m-%d", time_zone: Time.zone).count.each do |date, count|
        counts[date] += count
      end
      entry_sheet_item_templates.group_by_day(:updated_at, range: range, format: "%Y-%m-%d", time_zone: Time.zone).count.each do |date, count|
        counts[date] += count
      end
      counts
    end
  end

  def activity_active_dates
    @activity_active_dates ||= extract_active_dates(activity_counts_by_day).sort
  end

  def streak_achieved_dates(levels)
    achieved = {}
    streak = 0
    prev = nil
    activity_active_dates.each do |date|
      streak = (prev && date == prev + 1) ? streak + 1 : 1
      levels.each do |level|
        next if achieved.key?(level)
        achieved[level] = date if streak >= level
      end
      prev = date
    end
    achieved
  end

  def weekly_achievement_dates
    weeks = activity_active_dates.group_by(&:beginning_of_week)
    weeks.keys.sort.filter_map do |week_start|
      week_dates = weeks[week_start].sort
      next if week_dates.length < WEEKLY_GOAL

      week_dates[WEEKLY_GOAL - 1]
    end
  end

  def monthly_achievement_dates
    months = activity_active_dates.group_by { |date| date.beginning_of_month }
    months.keys.sort.filter_map do |month_start|
      month_dates = months[month_start].sort
      next if month_dates.length < MONTHLY_GOAL

      month_dates[MONTHLY_GOAL - 1]
    end
  end

  def threshold_dates_from_scope(scope, timestamp_column, thresholds)
    limit = thresholds.max.to_i
    return thresholds.to_h { |threshold| [ threshold, nil ] } if limit.zero?

    dates = scope.order(timestamp_column).limit(limit).pluck(timestamp_column)
    thresholds.to_h { |threshold| [ threshold, dates[threshold - 1] ] }
  end

  def threshold_dates_from_occurrences(dates, thresholds)
    thresholds.to_h { |threshold| [ threshold, dates[threshold - 1] ] }
  end

  def mutual_follow_timestamps
    @mutual_follow_timestamps ||= begin
      pairs = Follow.joins(
        "INNER JOIN follows AS inverse_follows " \
        "ON inverse_follows.follower_id = follows.followed_id " \
        "AND inverse_follows.followed_id = follows.follower_id"
      ).where(follows: { follower_id: id })
       .pluck("follows.followed_id", "follows.created_at", "inverse_follows.created_at")

      pairs.map { |_, created_at, inverse_created_at| [ created_at, inverse_created_at ].max }.sort
    end
  end

  def company_progress_timestamps
    @company_progress_timestamps ||= begin
      seen = {}
      timestamps = []
      posts.job_hunting.includes(:contentable).order(:created_at).each do |post|
        content = post.contentable
        company_name = content&.normalized_company_name
        next if company_name.blank? || seen[company_name]

        seen[company_name] = true
        timestamps << post.created_at
      end
      timestamps
    end
  end
end
