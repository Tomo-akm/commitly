class Follow < ApplicationRecord
  # 1. アソシエーション
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  # 2. 一意性の担保 (モデル層)
  validates :follower_id, uniqueness: { scope: :followed_id }

  # 3. 自分自身へのフォロー禁止 (Rails 7+ の新しい書き方)
  validates :followed_id, comparison: { other_than: :follower_id, message: "cannot follow yourself" }
end
