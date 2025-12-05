class Message < ApplicationRecord
  acts_as_message tool_calls_foreign_key: :message_id
  has_many_attached :attachments

  # ストリーミング中のチャンクをブロードキャスト
  def broadcast_append_chunk(chunk_content)
    # contentに追加
    self.content ||= ""
    self.content += chunk_content
    save!

    # Turbo Streamでcontentのみ更新（Markdown形式でレンダリング）
    broadcast_update_to(
      "chat_#{chat_id}",
      target: "message_#{id}_content",
      html: ApplicationController.helpers.markdown(content)
    )
  end
end
