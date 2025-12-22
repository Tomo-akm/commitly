module Llm
  class ClientFactory
    def self.build(provider:, api_key:)
      case provider.to_s
      when "openai"
        # OpenAI公式SDK
        OpenAI::Client.new(api_key: api_key)
      when "anthropic"
        # Anthropic公式SDK
        Anthropic::Client.new(api_key: api_key)
      when "google_ai_studio"
        # REST streamingのためSDK不要
        nil
      else
        raise "Unknown provider: #{provider}"
      end
    end
  end
end
