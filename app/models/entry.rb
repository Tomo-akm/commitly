class Entry < ApplicationRecord
  belongs_to :user
  belongs_to :room

  validates :user_id, uniqueness: { scope: :room_id }

  # 未読メッセージ数を取得
  def unread_count
    if last_read_at
      room.direct_messages.where("created_at > ?", last_read_at).count
    else
      # 初回の場合は全メッセージを未読として扱う
      room.direct_messages.count
    end
  end

  # 既読にする
  def mark_as_read!
    update(last_read_at: Time.current)
  end
end
