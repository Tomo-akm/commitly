class DirectMessage < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :content, presence: true, length: { maximum: 5000 }

  after_create_commit :broadcast_message

  private

  def broadcast_message
    room.entries.includes(:user).each do |entry|
      # メッセージを追加
      broadcast_append_later_to(
        User.room_detail_channel(room.id, entry.user_id),
        target: "messages",
        partial: "direct_messages/direct_message",
        locals: { direct_message: self, current_user: entry.user }
      )

      # 送信者以外には未読バッジも更新
      next if entry.user_id == user_id

      recipient = entry.user

      # DM一覧の該当ルームを更新（notification_channelで全画面に通知）
      # ルームを開いている場合も、別画面にいる場合も、このチャネルでカバーされる
      recipient.broadcast_room_list_item(room)
      recipient.broadcast_unread_badges
    end
  end
end
