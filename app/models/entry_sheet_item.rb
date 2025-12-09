class EntrySheetItem < ApplicationRecord
  belongs_to :entry_sheet
  belongs_to :entry_sheet_item_template, optional: true

  # バリデーション
  validates :title, presence: true
  validates :content, presence: true
  validates :char_limit, numericality: { greater_than: 0, allow_nil: true }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  # スコープ
  scope :ordered, -> { order(position: :asc) }

  # 現在の文字数を取得
  def char_count
    content.to_s.length
  end

  # 文字数制限を超えているか
  def over_limit?
    return false if char_limit.nil?
    char_count > char_limit
  end
end
