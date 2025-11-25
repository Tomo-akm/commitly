class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id

  belongs_to :user
  belongs_to :chattable, polymorphic: true, optional: true
  belongs_to :model, optional: true

  validates :user, presence: true

  scope :general, -> { where(chattable_type: nil) }
  scope :for_entry_sheet, ->(entry_sheet) { where(chattable: entry_sheet) }
  scope :for_entry_sheet_item, ->(item) { where(chattable: item) }
  scope :recent, -> { order(created_at: :desc) }

  # チャット種別の判定
  def general_chat?
    chattable_type.nil?
  end

  def entry_sheet_review?
    chattable_type == "EntrySheet"
  end

  def entry_sheet_item_review?
    chattable_type == "EntrySheetItem"
  end

  # 表示用タイトル
  def display_title
    return title if general_chat?

    case chattable_type
    when "EntrySheet"
      "#{chattable.company_name} - 全体添削"
    when "EntrySheetItem"
      "#{chattable.entry_sheet.company_name} - #{chattable.title}"
    end
  end

  # 現在のモデルのプロバイダーを取得
  def current_provider
    model&.provider || "openai"
  end
end
