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
  WEEKLY_DAYS = 7
  MONTHLY_DAYS = 30

  # アクティビティサマリーを作成
  #
  # @param counts_by_day [Hash] 日付文字列をキー、活動回数を値とするハッシュ
  #   例: { "2024-01-01" => 2, "2024-01-02" => 1 }
  # @return [Hash] 集計済みアクティビティ情報
  def activity_summary_from_counts(counts_by_day)
    active_dates = extract_active_dates(counts_by_day)

    {
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
  def count_active_days_in_range(active_dates, days)
    today = Date.current
    range_start = today - (days - 1)

    active_dates.count { |date| date >= range_start && date <= today }
  end

  # 進捗パーセンテージを計算
  def calculate_progress_percentage(active_days, goal)
    return 0 if goal.zero?

    percentage = ((active_days.to_f / goal) * 100).round
    [ percentage, 100 ].min
  end

  def achievement_snapshot
    @achievement_snapshot ||= begin
      post_count, post_first = activity_stats(posts, :created_at)
      follow_count, follow_first = activity_stats(active_follows, :created_at)
      es_count, es_first = activity_stats(entry_sheets.publicly_visible, :updated_at)
      review_count, review_first = activity_stats(
        posts.joins(:tags).where(tags: { name: "ESレビュー" }),
        :created_at
      )

      {
        flags: {
          first_post: post_count.positive?,
          first_follow: follow_count.positive?,
          first_es_public: es_count.positive?,
          first_review_request: review_count.positive?
        },
        history: {
          first_post: post_first,
          first_follow: follow_first,
          first_es_public: es_first,
          first_review_request: review_first
        }
      }
    end
  end

  def activity_stats(scope, timestamp_column)
    table = scope.klass.arel_table
    count_node = Arel::Nodes::NamedFunction.new("COUNT", [ Arel.star ])
    min_node = Arel::Nodes::NamedFunction.new("MIN", [ table[timestamp_column] ])
    count, first_at = scope.pick(count_node, min_node)
    [ count.to_i, first_at ]
  end
end
