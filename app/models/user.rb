# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :replies, dependent: :destroy

  validates :name, presence: true
  validates :internship_count,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 },
            allow_blank: true

  DEFAULT_INTERNSHIP_COUNT = 0

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

  private

  # OAuth認証データから名前を抽出
  def self.extract_name_from_auth(auth)
    auth.info.name.presence || auth.info.email.split("@").first
  end
end
