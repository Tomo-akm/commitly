# ユーザーへのリアルタイム通知機能を提供するConcern
module Notifiable
  extend ActiveSupport::Concern

  # 未読バッジの表示先とCSSクラスの定義
  BADGE_TARGETS = {
    "left_unread_badge" => "badge bg-danger rounded-pill ms-auto",
    "bottom_unread_badge" => "bottom-tab-bar__badge"
  }.freeze

  # ユーザーの全未読バッジをブロードキャスト更新
  def broadcast_unread_badges
    total_unread = total_unread_messages_count
    channel = self.class.notification_channel(id)

    BADGE_TARGETS.each do |target_id, badge_class|
      Turbo::StreamsChannel.broadcast_replace_later_to(
        channel,
        target: target_id,
        partial: "shared/unread_badge",
        locals: { count: total_unread, badge_class: badge_class, target_id: target_id }
      )
    end
  end

  # DM一覧の特定ルームアイテムをブロードキャスト更新
  def broadcast_room_list_item(room)
    Turbo::StreamsChannel.broadcast_replace_later_to(
      self.class.notification_channel(id),
      target: "room_#{room.id}",
      partial: "rooms/room_list_item",
      locals: { room: room, current_user: self }
    )
  end
end
