class EntrySheetItemTemplate < ApplicationRecord
  belongs_to :user
  has_many :entry_sheet_items, dependent: :nullify

  # タグの定数定義
  TAGS = [
    "ガクチカ",
    "自己PR",
    "志望動機",
    "挫折経験",
    "強み・弱み",
    "成果物",
    "インターン経験・エンジニアバイト経験",
    "プログラミングスキル",
    "研究情報",
    "その他"
  ].freeze

  # バリデーション
  validates :tag, presence: true, inclusion: { in: TAGS }
  validates :title, presence: true
  validates :content, presence: true

  # スコープ
  scope :by_tag, ->(tag) { where(tag: tag) }
  scope :recent, -> { order(created_at: :desc) }

  # セレクトボックス用
  def self.tags_for_select
    TAGS.map { |tag| [ tag, tag ] }
  end
end
