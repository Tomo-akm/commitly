class EntrySheet < ApplicationRecord
  belongs_to :user
  has_many :entry_sheet_items, dependent: :destroy

  # ステータスのenum定義
  enum :status, {
    draft: 0,          # 下書き
    in_progress: 1,    # 作成中
    completed: 2,      # 完成
    submitted: 3,      # 提出済み
    passed: 4,         # 通過
    failed: 5          # 不合格
  }, prefix: true

  # バリデーション
  validates :company_name, presence: true
  validates :status, presence: true

  # スコープ
  scope :upcoming_deadline, -> { where.not(deadline: nil).order(deadline: :asc) }
  scope :recent, -> { order(created_at: :desc) }

  # ネストフォーム用
  accepts_nested_attributes_for :entry_sheet_items,
                                allow_destroy: true,
                                reject_if: :all_blank
end
