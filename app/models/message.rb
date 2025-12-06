class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :model, optional: true

  def broadcast_append_chunk(chunk_content, save_to_db: false)
    self.content ||= ""
    self.content += chunk_content

    broadcast_update_to(
      "chat_#{chat_id}",
      target: "message_#{id}_content",
      html: ApplicationController.helpers.markdown(content)
    )

    save! if save_to_db
  end
end
