class Post < ApplicationRecord
  belongs_to :user
  belongs_to :contentable, polymorphic: true
  belongs_to :parent, class_name: "Post", optional: true
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :likes, dependent: :destroy
  has_many :replies, class_name: "Post", foreign_key: :parent_id, dependent: :destroy

  # contentable へのdelegation
  delegate :content, to: :contentable

  # contentableのバリデーションも実行
  validates_associated :contentable

  # Contentableタイプのマッピング
  CONTENTABLE_TYPES = {
    "general" => GeneralContent,
    "job_hunting" => JobHuntingContent
  }.freeze

  # 就活投稿の場合、企業名を自動でタグ化（create/update両方）
  after_save :update_company_tag_for_job_hunting, if: :job_hunting?

  # スコープ
  scope :general, -> { where(contentable_type: "GeneralContent") }
  scope :job_hunting, -> { where(contentable_type: "JobHuntingContent") }
  scope :with_tag, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) }
  scope :top_level, -> { where(parent_id: nil) } # リプライを除外（親投稿のみ）

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

  # 再帰的に全てのリプライ（子孫）をカウント（効率的なSQL CTEを使用）
  def all_replies_count
    # 再帰CTEを使って全ての子孫を1クエリで取得
    sql = <<-SQL.squish
      WITH RECURSIVE reply_tree AS (
        SELECT id, parent_id
        FROM posts
        WHERE parent_id = ?
        UNION ALL
        SELECT p.id, p.parent_id
        FROM posts p
        INNER JOIN reply_tree rt ON rt.id = p.parent_id
      )
      SELECT COUNT(*) FROM reply_tree
    SQL

    sanitized_sql = Post.sanitize_sql_array([sql, id])
    Post.connection.select_value(sanitized_sql).to_i
  end

  # 投稿タイプを判定
  def general?
    contentable_type == "GeneralContent"
  end

  def job_hunting?
    contentable_type == "JobHuntingContent"
  end

  # リプライかどうかを判定
  def reply?
    parent_id.present?
  end

  # タイプに応じてcontentableを構築
  def build_contentable(type = "general")
    type = "general" if type.blank?
    contentable_class = CONTENTABLE_TYPES[type]
    raise ArgumentError, "不明な投稿タイプ: #{type}" unless contentable_class

    self.contentable = contentable_class.new
  end

  # クラスメソッド：タイプに応じてPostとcontentableを構築
  def self.build_with_type(type = "general")
    type = "general" if type.blank?
    new.tap do |post|
      post.build_contentable(type)
    end
  end

  # フォームパラメータで更新（contentable + 追加パラメータ）
  def update_with_form_params(contentable_params, additional_params = {})
    contentable.assign_attributes(contentable_params)


    # 通常投稿は本文からハッシュタグを抽出してタグに反映
    apply_hashtags_from_content if general?

    # バリデーションチェック（validates_associated :contentable を含む）
    return false unless valid?

    # バリデーション成功時のみ保存
    transaction do
      contentable.save!
      save!
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  # 就活投稿の場合、企業名をタグとして更新（create/update両方）
  def update_company_tag_for_job_hunting
    return unless contentable.respond_to?(:normalized_company_name)

    normalized_name = contentable.normalized_company_name
    return if normalized_name.blank?

    # 企業名タグを作成または取得（失敗時は例外を投げる）
    tag = Tag.find_or_create_by_names([ normalized_name ]).first

    # 既存のタグをクリアして新しいタグを設定
    self.tags = [ tag ]
  end

  # 本文に含まれるハッシュタグをタグとして設定
  def apply_hashtags_from_content
    hashtag_names = Tag.extract_from_text(contentable.content.to_s)
    self.tags = Tag.find_or_create_by_names(hashtag_names)
  end
end
