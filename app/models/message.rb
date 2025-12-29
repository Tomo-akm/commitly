class Message < ApplicationRecord
  belongs_to :chat

  def broadcast_append_chunk(chunk_content, save_to_db: false)
    self.content ||= ""
    self.content += chunk_content

    Rails.logger.info "[Broadcast] message_id=#{id} bytes=#{chunk_content.to_s.bytesize} t=#{Process.clock_gettime(Process::CLOCK_MONOTONIC)}"

    broadcast_update_to(
      "chat_#{chat_id}",
      target: "message_#{id}_content",
      html: ApplicationController.helpers.markdown(content)
    )

    save! if save_to_db
  end
end
