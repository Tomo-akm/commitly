# frozen_string_literal: true

# 実績マスターデータ
class Achievement < ActiveHash::Base
  self.data = [
    { id: 1, key: :first_post, label: "ファーストコミット", icon: "fa-pen-nib", badge: "first_post", hint: "初めて投稿すると達成" },
    { id: 2, key: :first_follow, label: "リンクスタート", icon: "fa-user-plus", badge: "first_follow", hint: "初めてフォローすると達成" },
    { id: 3, key: :first_es_public, label: "ESオープン", icon: "fa-globe", badge: "first_es_public", hint: "ESを公開にすると達成" },
    { id: 4, key: :first_review_request, label: "レビューコール", icon: "fa-comments", badge: "first_review_request", hint: "投稿に#ESレビューを付けると達成" },

    { id: 11, key: :streak_7, label: "フレイムストリーク・ブロンズ", icon: "fa-fire", badge: "streak_7", hint: "連続コミットが7日続くと達成", series: "streak", series_label: "フレイムストリーク", level: 1, level_label: "7日", tier_label: "ブロンズ" },
    { id: 12, key: :streak_14, label: "フレイムストリーク・シルバー", icon: "fa-fire", badge: "streak_14", hint: "連続コミットが14日続くと達成", series: "streak", series_label: "フレイムストリーク", level: 2, level_label: "14日", tier_label: "シルバー" },
    { id: 13, key: :streak_30, label: "フレイムストリーク・ゴールド", icon: "fa-fire", badge: "streak_30", hint: "連続コミットが30日続くと達成", series: "streak", series_label: "フレイムストリーク", level: 3, level_label: "30日", tier_label: "ゴールド" },

    { id: 21, key: :weekly_goal_1, label: "週間スプリント・ブロンズ", icon: "fa-bolt", badge: "weekly_goal_1", hint: "週目標を達成した週が1回になると獲得", series: "weekly_goal", series_label: "週間スプリント", level: 1, level_label: "1週", tier_label: "ブロンズ" },
    { id: 22, key: :weekly_goal_2, label: "週間スプリント・シルバー", icon: "fa-bolt", badge: "weekly_goal_2", hint: "週目標を達成した週が2回になると獲得", series: "weekly_goal", series_label: "週間スプリント", level: 2, level_label: "2週", tier_label: "シルバー" },
    { id: 23, key: :weekly_goal_3, label: "週間スプリント・ゴールド", icon: "fa-bolt", badge: "weekly_goal_3", hint: "週目標を達成した週が3回になると獲得", series: "weekly_goal", series_label: "週間スプリント", level: 3, level_label: "3週", tier_label: "ゴールド" },

    { id: 31, key: :monthly_goal_1, label: "月間マイルストーン・ブロンズ", icon: "fa-medal", badge: "monthly_goal_1", hint: "月目標を達成した月が1回になると獲得", series: "monthly_goal", series_label: "月間マイルストーン", level: 1, level_label: "1ヶ月", tier_label: "ブロンズ" },
    { id: 32, key: :monthly_goal_2, label: "月間マイルストーン・シルバー", icon: "fa-medal", badge: "monthly_goal_2", hint: "月目標を達成した月が2回になると獲得", series: "monthly_goal", series_label: "月間マイルストーン", level: 2, level_label: "2ヶ月", tier_label: "シルバー" },
    { id: 33, key: :monthly_goal_3, label: "月間マイルストーン・ゴールド", icon: "fa-medal", badge: "monthly_goal_3", hint: "月目標を達成した月が3回になると獲得", series: "monthly_goal", series_label: "月間マイルストーン", level: 3, level_label: "3ヶ月", tier_label: "ゴールド" },

    { id: 41, key: :es_public_3, label: "オープンアーカイブ・ブロンズ", icon: "fa-globe", badge: "es_public_3", hint: "公開したESが3件に到達すると達成", series: "es_public", series_label: "オープンアーカイブ", level: 1, level_label: "3件", tier_label: "ブロンズ" },
    { id: 42, key: :es_public_5, label: "オープンアーカイブ・シルバー", icon: "fa-globe", badge: "es_public_5", hint: "公開したESが5件に到達すると達成", series: "es_public", series_label: "オープンアーカイブ", level: 2, level_label: "5件", tier_label: "シルバー" },
    { id: 43, key: :es_public_10, label: "オープンアーカイブ・ゴールド", icon: "fa-globe", badge: "es_public_10", hint: "公開したESが10件に到達すると達成", series: "es_public", series_label: "オープンアーカイブ", level: 3, level_label: "10件", tier_label: "ゴールド" },

    { id: 51, key: :review_request_3, label: "レビューコール・ブロンズ", icon: "fa-comments", badge: "review_request_3", hint: "投稿に#ESレビューを3回付けると達成", series: "review_request", series_label: "レビューコール", level: 1, level_label: "3回", tier_label: "ブロンズ" },
    { id: 52, key: :review_request_5, label: "レビューコール・シルバー", icon: "fa-comments", badge: "review_request_5", hint: "投稿に#ESレビューを5回付けると達成", series: "review_request", series_label: "レビューコール", level: 2, level_label: "5回", tier_label: "シルバー" },
    { id: 53, key: :review_request_10, label: "レビューコール・ゴールド", icon: "fa-comments", badge: "review_request_10", hint: "投稿に#ESレビューを10回付けると達成", series: "review_request", series_label: "レビューコール", level: 3, level_label: "10回", tier_label: "ゴールド" },

    { id: 61, key: :mutual_follow_5, label: "リンクチェーン・ブロンズ", icon: "fa-user-friends", badge: "mutual_follow_5", hint: "相互フォローが5人になると達成", series: "mutual_follow", series_label: "リンクチェーン", level: 1, level_label: "5人", tier_label: "ブロンズ" },
    { id: 62, key: :mutual_follow_10, label: "リンクチェーン・シルバー", icon: "fa-user-friends", badge: "mutual_follow_10", hint: "相互フォローが10人になると達成", series: "mutual_follow", series_label: "リンクチェーン", level: 2, level_label: "10人", tier_label: "シルバー" },
    { id: 63, key: :mutual_follow_20, label: "リンクチェーン・ゴールド", icon: "fa-user-friends", badge: "mutual_follow_20", hint: "相互フォローが20人になると達成", series: "mutual_follow", series_label: "リンクチェーン", level: 3, level_label: "20人", tier_label: "ゴールド" },

    { id: 71, key: :template_3, label: "テンプレ工房・ブロンズ", icon: "fa-layer-group", badge: "template_3", hint: "ESテンプレートを3件作成すると達成", series: "template", series_label: "テンプレ工房", level: 1, level_label: "3件", tier_label: "ブロンズ" },
    { id: 72, key: :template_5, label: "テンプレ工房・シルバー", icon: "fa-layer-group", badge: "template_5", hint: "ESテンプレートを5件作成すると達成", series: "template", series_label: "テンプレ工房", level: 2, level_label: "5件", tier_label: "シルバー" },
    { id: 73, key: :template_7, label: "テンプレ工房・ゴールド", icon: "fa-layer-group", badge: "template_7", hint: "ESテンプレートを7件作成すると達成", series: "template", series_label: "テンプレ工房", level: 3, level_label: "7件", tier_label: "ゴールド" },

    { id: 81, key: :company_progress_3, label: "企業トラッカー・ブロンズ", icon: "fa-briefcase", badge: "company_progress_3", hint: "企業別進捗を3社登録すると達成", series: "company_progress", series_label: "企業トラッカー", level: 1, level_label: "3社", tier_label: "ブロンズ" },
    { id: 82, key: :company_progress_5, label: "企業トラッカー・シルバー", icon: "fa-briefcase", badge: "company_progress_5", hint: "企業別進捗を5社登録すると達成", series: "company_progress", series_label: "企業トラッカー", level: 2, level_label: "5社", tier_label: "シルバー" },
    { id: 83, key: :company_progress_7, label: "企業トラッカー・ゴールド", icon: "fa-briefcase", badge: "company_progress_7", hint: "企業別進捗を7社登録すると達成", series: "company_progress", series_label: "企業トラッカー", level: 3, level_label: "7社", tier_label: "ゴールド" }
  ]

  # キーで実績を検索
  def self.find_by_key(key)
    find_by(key: key)
  end

  # 達成済みの実績を取得
  def self.achieved_by(achievement_flags)
    all.select { |achievement| achievement_flags[achievement.key] }
  end

  # 表示用の実績を取得（達成済みでリミット適用）
  # 最新の実績から表示するため last を使用
  def self.for_display(achievement_flags, limit: 3)
    achieved_by(achievement_flags).last(limit)
  end
end
