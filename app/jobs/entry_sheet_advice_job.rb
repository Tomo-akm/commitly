class EntrySheetAdviceJob < ApplicationJob
  include EntrySheetAdvicePromptable
  queue_as :default

  def perform(entry_sheet_item_id, user_id, title, content, char_limit)
    Rails.logger.info "[EntrySheetAdviceJob] ジョブ開始: item=#{entry_sheet_item_id}, user=#{user_id}"

    @entry_sheet_item = EntrySheetItem.find(entry_sheet_item_id)
    @user = User.find(user_id)

    chat = @entry_sheet_item.chat or raise "Chatが見つかりません"

    prompt = build_advice_prompt(
      company_name: @entry_sheet_item.entry_sheet.company_name,
      title: title,
      content: content,
      char_limit: char_limit
    )

    service = Llm::ChatService.new

    messages = [ { role: "user", content: prompt } ]
    message = chat.messages.create!(role: "assistant", content: "")

    chunk_count = 0
    save_interval = 10

    service.stream(messages: messages) do |text|
      next if text.blank?

      broadcast_first_message(message, @entry_sheet_item.id) if message.content.blank?

      chunk_count += 1
      should_save = (chunk_count % save_interval).zero?
      message.broadcast_append_chunk(text, save_to_db: should_save)
    end

    message.save!
  rescue StandardError=> e
    Rails.logger.error("ES添削ERROR: #{e.class} - #{e.message}")
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
