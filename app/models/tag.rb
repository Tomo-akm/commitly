class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  scope :popular, -> { order(posts_count: :desc) }
  scope :with_posts, -> { where("posts_count > 0") }

  before_save :normalize_name

  # ハッシュタグを検出する正規表現（Unicode文字、数字、アンダースコアに対応）
  # ハッシュタグの前に空白（半角・全角）または行頭、後ろに空白または行末が必要
  # \u3000 = 全角スペース
  HASHTAG_REGEX = /(?:^|[\s\u3000])#([\p{Letter}\p{Number}_]+)(?=[\s\u3000]|$)/u

  # Ransackの設定
  def self.ransackable_attributes(auth_object = nil)
    %w[name posts_count created_at]
  end

  # テキストからハッシュタグを抽出（完全一致で重複排除）
  def self.extract_from_text(text)
    return [] if text.blank?

    text.scan(HASHTAG_REGEX).flatten.map(&:strip).uniq
  end

  def self.find_or_create_by_names(tag_names)
    return [] if tag_names.blank?

    Array(tag_names).map do |name|
      name = name.to_s.strip
      next if name.blank?

      find_or_create_by!(name: name)
    end.compact
  end

  private

  def normalize_name
    self.name = name.to_s.strip
  end
end
