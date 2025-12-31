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

  # 公開範囲のenum定義
  enum :visibility, {
    personal: 0,  # 非公開（自分のみ）
    shared: 1     # 公開（全ユーザー）
  }, prefix: true

  # バリデーション
  validates :company_name, presence: true
  validates :status, presence: true

  # スコープ
  scope :upcoming_deadline, lambda {
    where.not(deadline: nil)
         .where(deadline: Time.current..2.weeks.from_now)
         .order(deadline: :asc)
  }
  scope :recent, -> { order(created_at: :desc) }
  scope :publicly_visible, -> { where(visibility: :shared) }

  # 指定したユーザーが閲覧可能か判定
  def viewable_by?(user)
    self.user_id == user.id || visibility_shared?
  end

  # ネストフォーム用
  accepts_nested_attributes_for :entry_sheet_items,
                                allow_destroy: true,
                                reject_if: :all_blank
end
