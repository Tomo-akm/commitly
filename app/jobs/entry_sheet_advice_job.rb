class EntrySheetAdviceJob < ApplicationJob
  include EntrySheetAdvicePromptable
  queue_as :default

  SAVE_INTERVAL = 10

  def perform(entry_sheet_item_id, user_id, title, content, char_limit)
    @entry_sheet_item = EntrySheetItem.find(entry_sheet_item_id)
    @user = User.find(user_id)

    execute_advice(title, content, char_limit)

    Rails.logger.info "[EntrySheetAdviceJob] 完了: 残り#{LlmUsage.remaining_count(@user)}回"
  rescue StandardError => e
    Rails.logger.error "[EntrySheetAdviceJob] エラー: #{e.class} - #{e.message}"
    raise
  end

  private

  def execute_advice(title, content, char_limit)
    chat = @entry_sheet_item.chat or raise "Chatが見つかりません"
    prompt = build_prompt(title, content, char_limit)
    message = chat.messages.create!(role: "assistant", content: "")

    stream_llm_response(prompt, message)
    message.save!
  end

  def build_prompt(title, content, char_limit)
    build_advice_prompt(
      company_name: @entry_sheet_item.entry_sheet.company_name,
      title: title,
      content: content,
      char_limit: char_limit
    )
  end

  def stream_llm_response(prompt, message)
    service = Llm::ChatService.new
    messages = [ { role: "user", content: prompt } ]
    chunk_count = 0

    service.stream(messages: messages) do |text|
      next if text.blank?

      broadcast_first_message(message, @entry_sheet_item.id) if message.content.blank?

      chunk_count += 1
      should_save = (chunk_count % SAVE_INTERVAL).zero?
      message.broadcast_append_chunk(text, save_to_db: should_save)
    end
  end

  def broadcast_first_message(message, entry_sheet_item_id)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{message.chat_id}",
      target: "advice_messages_#{entry_sheet_item_id}",
      partial: "messages/message",
      locals: { message: message }
    )
  end
end
