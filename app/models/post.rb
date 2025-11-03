class Post < ApplicationRecord
  belongs_to :user
  belongs_to :contentable, polymorphic: true
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :likes, dependent: :destroy

  # contentable へのdelegation
  delegate :content, to: :contentable

  # contentableのバリデーションも実行
  validates_associated :contentable

  # 就活投稿の場合、企業名を自動でタグ化（create/update両方）
  after_save :update_company_tag_for_job_hunting, if: :job_hunting?

  # スコープ
  scope :general, -> { where(contentable_type: "GeneralContent") }
  scope :job_hunting, -> { where(contentable_type: "JobHuntingContent") }
  scope :with_tag, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) }

  # Ransackの設定
  def self.ransackable_attributes(auth_object = nil)
    %w[created_at contentable_type content_search]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user tags contentable]
  end

  # カスタム検索用のransacker
  ransacker :content_search do
    Arel.sql("CASE
      WHEN posts.contentable_type = 'GeneralContent'
        THEN (SELECT content FROM general_contents WHERE general_contents.id = posts.contentable_id)
      WHEN posts.contentable_type = 'JobHuntingContent'
        THEN (SELECT content FROM job_hunting_contents WHERE job_hunting_contents.id = posts.contentable_id)
    END")
  end

  # タグ名の配列を受け取ってタグを設定
  def tag_names=(names)
    tag_list = names.is_a?(String) ? names.split(",") : names
    tag_list = tag_list.map(&:strip).reject(&:blank?)
    self.tags = Tag.find_or_create_by_names(tag_list)
  end

  def tag_names
    tags.pluck(:name).join(", ")
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end

  def likes_count
    likes.count
  end

  # 投稿タイプを判定
  def general?
    contentable_type == "GeneralContent"
  end

  def job_hunting?
    contentable_type == "JobHuntingContent"
  end

  private

  # 就活投稿の場合、企業名をタグとして更新（create/update両方）
  def update_company_tag_for_job_hunting
    return unless contentable.respond_to?(:normalized_company_name)

    normalized_name = contentable.normalized_company_name
    return if normalized_name.blank?

    # 企業名タグを作成または取得（失敗時は例外を投げる）
    tag = Tag.find_or_create_by!(name: normalized_name.downcase)

    # 既存のタグをクリアして新しいタグを設定
    self.tags = [ tag ]
  end
end
