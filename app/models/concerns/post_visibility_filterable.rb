# frozen_string_literal: true

# 投稿の公開範囲フィルタリングロジック
module PostVisibilityFilterable
  extend ActiveSupport::Concern

  included do
    # 閲覧可能な投稿のみを取得するスコープ
    scope :visible_to, ->(viewer) {
      # ログアウト状態では全体公開のみ表示
      if viewer.nil?
        return joins(:user).where(users: { post_visibility: User.post_visibilities[:everyone] })
      end

      # OR条件で1つのクエリに最適化
      # 1. 本人の投稿
      # 2. 全体公開の投稿
      # 3. 相互フォローのみの投稿（相互フォロー関係のユーザー）
      joins(:user)
        .joins(sanitize_sql_array([
          "LEFT OUTER JOIN follows AS f1 ON f1.followed_id = users.id AND f1.follower_id = ?",
          viewer.id
        ]))
        .joins(sanitize_sql_array([
          "LEFT OUTER JOIN follows AS f2 ON f2.follower_id = users.id AND f2.followed_id = ?",
          viewer.id
        ]))
        .where(
          "posts.user_id = :viewer_id OR " \
          "users.post_visibility = :everyone OR " \
          "(users.post_visibility = :mutual_followers AND f1.id IS NOT NULL AND f2.id IS NOT NULL)",
          viewer_id: viewer.id,
          everyone: User.post_visibilities[:everyone],
          mutual_followers: User.post_visibilities[:mutual_followers]
        )
        .distinct
    }
  end

  # リプライの閲覧可能性を判定
  def visible_to?(viewer)
    return true if viewer == user # 本人は常に閲覧可能
    return true if parent&.user == viewer # 親投稿の作成者は常に閲覧可能

    case user.post_visibility
    when "everyone"
      true
    when "mutual_followers"
      viewer&.mutual_follow?(user)
    when "only_me"
      false
    else
      false
    end
  end
end