module Llm
  class ChatService
    def initialize
      @api_key = Rails.application.credentials.dig(:google_ai_studio, :api_key)
      raise "Google AI Studio APIキーが設定されていません" if @api_key.blank?
      @client = Llm::GeminiClient.new(api_key: @api_key)
    end

    def stream(messages:, model: "gemini-3-flash-preview", &block)
      @client.stream(messages: messages, model: model, &block)
    end
  end
end
