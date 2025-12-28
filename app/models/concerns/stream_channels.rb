module StreamChannels
  extend ActiveSupport::Concern

  class_methods do
    def notification_channel(user_id)
      "user_#{user_id}_notifications"
    end

    def room_detail_channel(room_id, user_id)
      "room_#{room_id}_user_#{user_id}"
    end
  end

  def notification_channel
    self.class.notification_channel(id)
  end

  def room_detail_channel(room_id)
    self.class.room_detail_channel(room_id, id)
  end
end
