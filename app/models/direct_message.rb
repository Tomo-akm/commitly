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

      # DM一覧の該当ルームを更新（同じルームを開いている場合）
      broadcast_replace_later_to(
        recipient.room_detail_channel(room.id),
        target: "room_#{room.id}",
        partial: "rooms/room_list_item",
        locals: { room: room, current_user: recipient }
      )

      # DM一覧の該当ルームを更新とバッジ更新（別のルームや別画面でも通知）
      recipient.broadcast_room_list_item(room)
      recipient.broadcast_unread_badges
    end
  end
end
