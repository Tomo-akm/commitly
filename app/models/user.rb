# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_one_attached :avatar # ここを追加

  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :entries, dependent: :destroy
  has_many :rooms, through: :entries
  has_many :direct_messages, dependent: :destroy
  has_many :active_follows, class_name:  "Follow",
           foreign_key: "follower_id",
           dependent:   :destroy
  has_many :passive_follows, class_name:  "Follow",
           foreign_key: "followed_id",
           dependent:   :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  # 投稿の公開範囲設定
  enum :post_visibility, {
    everyone: 0,         # 全体公開
    mutual_followers: 1, # 相互フォローのみ
    only_me: 2           # 自分だけ
  }, default: :everyone

  # ユーザーをフォローする
  # Follow モデルのバリデーションにより自分自身のフォローや重複は自動的に防止される
  def follow(other_user)
    active_follows.create(followed: other_user)
  end

  # ユーザーをフォロー解除する
  def unfollow(other_user)
    active_follows.find_by(followed: other_user)&.destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す
  # exists? を使用してデータベースレベルで効率的にチェック
  def following?(other_user)
    active_follows.exists?(followed: other_user)
  end

  # 相互フォロー関係かどうかを判定
  def mutual_follow?(other_user)
    following?(other_user) && other_user.following?(self)
  end

  has_many :entry_sheets, dependent: :destroy
  has_many :entry_sheet_item_templates, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :api_keys, dependent: :destroy
  has_many :chats, dependent: :destroy

  validates :name, presence: true
  validates :internship_count,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 },
            allow_blank: true

  # アバター画像のバリデーション
  validates :avatar, content_type: { in: [ "image/png", "image/jpeg" ], message: "はPNGまたはJPEG形式を選択してください" },
                     size: { less_than: 5.megabytes, message: "は5MB以下の画像を選択してください" },
                     dimension: { width: { max: 4000 }, height: { max: 4000 } }

  DEFAULT_INTERNSHIP_COUNT = 0

  # アバター画像のURLを返す（リサイズ対応）
  def avatar_url(size: 100)
    unless avatar.attached?
      return "https://api.dicebear.com/8.x/bottts/svg?seed=#{avatar_seed}&size=#{size}"
    end
    Rails.application.routes.url_helpers.rails_representation_url(
      avatar.variant(resize_to_limit: [ size, size ]).processed,
      only_path: true
    )
  end

  # OmniAuth経由のユーザー作成または取得
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = extract_name_from_auth(auth)
      user.password = Devise.friendly_token[0, 20]
      user.internship_count = DEFAULT_INTERNSHIP_COUNT
    end
  end

  # OmniAuth経由の場合はパスワード検証をスキップ
  def password_required?
    super && provider.blank?
  end

  def email_required?
    super && provider.blank?
  end

  # 全未読メッセージ数
  def total_unread_messages_count
    entries.sum(&:unread_count)
  end

  private

  # アバター画像のシード値を生成（個人情報を含まないハッシュ値）
  def avatar_seed
    Digest::SHA256.hexdigest("#{id}-#{email}-#{Rails.application.secret_key_base}")
  end

  # OAuth認証データから名前を抽出
  def self.extract_name_from_auth(auth)
    auth.info.name.presence || auth.info.email.split("@").first
  end
end
