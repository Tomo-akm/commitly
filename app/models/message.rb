class Message < ApplicationRecord
  acts_as_message tool_calls_foreign_key: :message_id
  has_many_attached :attachments

  # ストリーミング中のチャンクをブロードキャスト（DB保存は呼び出し側で制御）
  def broadcast_append_chunk(chunk_content, save_to_db: false)
    # contentに追加
    self.content ||= ""
    self.content += chunk_content

    # Turbo Streamでcontentのみ更新（Markdown形式でレンダリング）
    broadcast_update_to(
      "chat_#{chat_id}",
      target: "message_#{id}_content",
      html: ApplicationController.helpers.markdown(content)
    )

    # DB保存が必要な場合のみ保存
    save! if save_to_db
  end
end
