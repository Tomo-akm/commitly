class GeneralContent < ApplicationRecord
  has_one :post, as: :contentable, dependent: :destroy

  validates :content, presence: true, length: { maximum: 5000 }

  # プレゼンテーション用の定数
  TYPE_NAME = "general"
  TITLE = "つぶやき commit"
  SUCCESS_MESSAGE = "つぶやきをpushしました"
  REPLY_SUCCESS_MESSAGE = "replyをpushしました"

  # Ransackの設定（post経由で検索可能にする）
  def self.ransackable_attributes(auth_object = nil)
    %w[content]
  end

  # プレゼンテーション用メソッド（ポリモーフィックアクセス用）
  def type_name = TYPE_NAME
  def title = TITLE
  def success_message
    # リプライの場合は異なるメッセージを返す
    post&.reply? ? REPLY_SUCCESS_MESSAGE : SUCCESS_MESSAGE
  end
end
