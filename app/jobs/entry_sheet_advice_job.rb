class EntrySheetAdviceJob < ApplicationJob
  include EntrySheetAdvicePromptable
  include LlmApiKeyLoadable

  queue_as :default

  def perform(entry_sheet_item_id, user_id, model_id, current_title, current_content, current_char_limit)
    entry_sheet_item = EntrySheetItem.find(entry_sheet_item_id)
    user = User.find(user_id)
    model = Model.find(model_id)

    chat = entry_sheet_item.chat
    raise "Chatが見つかりません" unless chat

    load_llm_api_key(user: user, model: model)

    prompt = build_advice_prompt(
      company_name: entry_sheet_item.entry_sheet.company_name,
      title: current_title,
      content: current_content,
      char_limit: current_char_limit
    )

    chunk_count = 0
    save_interval = 10  # 10チャンクごとにDB保存

    chat.ask(prompt) do |chunk|
      next unless chunk.content.present?

      message = chat.messages.last
      broadcast_first_message(message, entry_sheet_item.id) if message.content.blank? && message.role == "assistant"

      chunk_count += 1
      should_save = (chunk_count % save_interval).zero?
      message.broadcast_append_chunk(chunk.content, save_to_db: should_save)
    end

    # ストリーミング完了後、最終保存
    chat.messages.last.save!
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("ES添削Job: レコードが見つかりません (#{e.message})")
    # レコードが削除された場合はジョブを失敗させるが、chatは保持
  rescue StandardError => e
    Rails.logger.error("ES添削エラー: #{e.message}")
    raise
  end

  private

  def broadcast_first_message(message, entry_sheet_item_id)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{message.chat_id}",
      target: "advice_messages_#{entry_sheet_item_id}",
      partial: "messages/message",
      locals: { message: message }
    )
  end
end
