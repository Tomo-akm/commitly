# frozen_string_literal: true

# 実績マスターデータ
class Achievement < ActiveHash::Base
  self.data = [
    { id: 1, key: :first_post, label: "初投稿", icon: "fa-pen-nib", badge: "first_post", hint: "初めて投稿すると達成" },
    { id: 2, key: :first_follow, label: "初フォロー", icon: "fa-user-plus", badge: "first_follow", hint: "初めてフォローすると達成" },
    { id: 3, key: :first_es_public, label: "初ES公開", icon: "fa-globe", badge: "first_es_public", hint: "ESを公開にすると達成" },
    { id: 4, key: :first_review_request, label: "初レビュー依頼", icon: "fa-comments", badge: "first_review_request", hint: "投稿に#ESレビューを付けると達成" },

    { id: 11, key: :streak_7, label: "連続コミット 7日", icon: "fa-fire", badge: "streak_7", hint: "連続コミットが7日続くと達成" },
    { id: 12, key: :streak_14, label: "連続コミット 14日", icon: "fa-fire", badge: "streak_14", hint: "連続コミットが14日続くと達成" },
    { id: 13, key: :streak_30, label: "連続コミット 30日", icon: "fa-fire", badge: "streak_30", hint: "連続コミットが30日続くと達成" },

    { id: 21, key: :weekly_goal_1, label: "週間達成 1回", icon: "fa-bolt", badge: "weekly_goal_1", hint: "週目標を達成した週が1回になると獲得" },
    { id: 22, key: :weekly_goal_2, label: "週間達成 2回", icon: "fa-bolt", badge: "weekly_goal_2", hint: "週目標を達成した週が2回になると獲得" },
    { id: 23, key: :weekly_goal_3, label: "週間達成 3回", icon: "fa-bolt", badge: "weekly_goal_3", hint: "週目標を達成した週が3回になると獲得" },

    { id: 31, key: :monthly_goal_1, label: "月間達成 1回", icon: "fa-medal", badge: "monthly_goal_1", hint: "月目標を達成した月が1回になると獲得" },
    { id: 32, key: :monthly_goal_2, label: "月間達成 2回", icon: "fa-medal", badge: "monthly_goal_2", hint: "月目標を達成した月が2回になると獲得" },
    { id: 33, key: :monthly_goal_3, label: "月間達成 3回", icon: "fa-medal", badge: "monthly_goal_3", hint: "月目標を達成した月が3回になると獲得" },

    { id: 41, key: :es_public_3, label: "ES公開 3", icon: "fa-globe", badge: "es_public_3", hint: "公開したESが3件に到達すると達成" },
    { id: 42, key: :es_public_5, label: "ES公開 5", icon: "fa-globe", badge: "es_public_5", hint: "公開したESが5件に到達すると達成" },
    { id: 43, key: :es_public_10, label: "ES公開 10", icon: "fa-globe", badge: "es_public_10", hint: "公開したESが10件に到達すると達成" },

    { id: 51, key: :review_request_3, label: "#ESレビュー 3", icon: "fa-comments", badge: "review_request_3", hint: "投稿に#ESレビューを3回付けると達成" },
    { id: 52, key: :review_request_5, label: "#ESレビュー 5", icon: "fa-comments", badge: "review_request_5", hint: "投稿に#ESレビューを5回付けると達成" },
    { id: 53, key: :review_request_10, label: "#ESレビュー 10", icon: "fa-comments", badge: "review_request_10", hint: "投稿に#ESレビューを10回付けると達成" },

    { id: 61, key: :mutual_follow_5, label: "相互フォロー 5", icon: "fa-user-friends", badge: "mutual_follow_5", hint: "相互フォローが5人になると達成" },
    { id: 62, key: :mutual_follow_10, label: "相互フォロー 10", icon: "fa-user-friends", badge: "mutual_follow_10", hint: "相互フォローが10人になると達成" },
    { id: 63, key: :mutual_follow_20, label: "相互フォロー 20", icon: "fa-user-friends", badge: "mutual_follow_20", hint: "相互フォローが20人になると達成" },

    { id: 71, key: :template_3, label: "ESテンプレ 3", icon: "fa-layer-group", badge: "template_3", hint: "ESテンプレートを3件作成すると達成" },
    { id: 72, key: :template_5, label: "ESテンプレ 5", icon: "fa-layer-group", badge: "template_5", hint: "ESテンプレートを5件作成すると達成" },
    { id: 73, key: :template_7, label: "ESテンプレ 7", icon: "fa-layer-group", badge: "template_7", hint: "ESテンプレートを7件作成すると達成" },

    { id: 81, key: :company_progress_3, label: "企業進捗 3社", icon: "fa-briefcase", badge: "company_progress_3", hint: "企業別進捗を3社登録すると達成" },
    { id: 82, key: :company_progress_5, label: "企業進捗 5社", icon: "fa-briefcase", badge: "company_progress_5", hint: "企業別進捗を5社登録すると達成" },
    { id: 83, key: :company_progress_7, label: "企業進捗 7社", icon: "fa-briefcase", badge: "company_progress_7", hint: "企業別進捗を7社登録すると達成" }
  ]

  # キーで実績を検索
  def self.find_by_key(key)
    find_by(key: key)
  end
end
