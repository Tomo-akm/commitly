module LlmApiKeyLoadable
  extend ActiveSupport::Concern

  private

  def load_llm_api_key(user:, model:)
    api_key = find_user_api_key(user, model.provider)
    configure_llm_provider(model.provider, api_key.api_key)
  end

  def find_user_api_key(user, provider)
    api_key = user.api_keys.for_provider(provider).first
    raise "#{provider}のAPIキーが登録されていません" unless api_key
    api_key
  end

  def configure_llm_provider(provider, key)
    case provider
    when "openai"
      RubyLLM.config.openai_api_key = key
    when "anthropic"
      RubyLLM.config.anthropic_api_key = key
    when "gemini"
      RubyLLM.config.gemini_api_key = key
    else
      raise "未対応のプロバイダー: #{provider}"
    end
  end
end
