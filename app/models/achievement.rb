# frozen_string_literal: true

# 実績マスターデータ
class Achievement < ActiveHash::Base
  self.data = [
    { id: 1, key: :first_post, label: "初投稿", icon: "fa-pen-nib", badge: "first_post", hint: "初めて投稿すると達成" },
    { id: 2, key: :first_follow, label: "初フォロー", icon: "fa-user-plus", badge: "first_follow", hint: "初めてフォローすると達成" },
    { id: 3, key: :first_es_public, label: "初ES公開", icon: "fa-globe", badge: "first_es_public", hint: "ESを公開にすると達成" },
    { id: 4, key: :first_review_request, label: "初レビュー依頼", icon: "fa-comments", badge: "first_review_request", hint: "投稿に#ESレビューを付けると達成" }
  ]

  # キーで実績を検索
  def self.find_by_key(key)
    find_by(key: key)
  end
end
