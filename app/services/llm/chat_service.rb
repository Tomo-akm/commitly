module Llm
  class ChatService
    def initialize(provider:, api_key:)
      @provider = provider.to_s
      @client = Llm::ClientFactory.build(provider:, api_key:)
    end

    def stream(messages:, model:, &block)
      case @provider
      when "anthropic"
        stream_anthropic(messages:, model:, &block)
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
        model: model.to_sym
      )

      stream.text.each do |text|
        block.call(text)
      end
    end
  end
end
