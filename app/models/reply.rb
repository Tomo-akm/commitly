class Reply < ApplicationRecord
  belongs_to :user
  belongs_to :post

  # 親リプライへの関連付け (optional: true で親がいなくてもOK = トップレベルリプライ)
  belongs_to :parent, class_name: "Reply", optional: true

  # 子リプライ（自分への返信）への関連付け
  # dependent: :destroy で親が削除されたら子も削除
  has_many :replies, class_name: "Reply", foreign_key: :parent_id, dependent: :destroy

  validates :content, presence: true, length: { maximum: 280 } # Twitterライクな文字数制限
end
