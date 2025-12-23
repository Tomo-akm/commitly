module Llm
  class ChatService
    def initialize(provider:, api_key:)
      @provider = provider.to_s
      @api_key = api_key
      @client = Llm::ClientFactory.build(provider:, api_key:)
    end

    def stream(messages:, model:, &block)
      case @provider
      when "anthropic"
        stream_anthropic(messages:, model:, &block)
      when "google_ai_studio"
        stream_google_ai_studio(messages:, model:, &block)
      else
        raise "Unknown provider: #{@provider}"
      end
    end

    private

    # TODO: OpenAI

    # Anthropic公式SDK（streaming helpers使用）
    def stream_anthropic(messages:, model:, &block)
      stream = @client.messages.stream(
        max_tokens: 2048,
        messages: messages,
        model: model.to_s
      )

      stream.text.each do |text|
        block.call(text)
      end
    end

    def stream_google_ai_studio(messages:, model:, &block)
      Llm::GeminiClient.new(api_key: @api_key).stream(messages:, model:, &block)
    end
  end
end
