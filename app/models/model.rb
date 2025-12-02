class Model < ApplicationRecord
  acts_as_model chats_foreign_key: :model_id

  ALLOWED_MODELS = {
    "anthropic" => %w[claude-opus-4-1 claude-sonnet-4-5 claude-haiku-4-5],
    "gemini" => %w[gemini-2.5-flash gemini-2.5-flash-lite gemini-2.5-pro],
    "openai" => %w[gpt-5 gpt-5-mini gpt-5-nano gpt-5-pro]
  }.freeze

  scope :without_dated_versions, -> { where.not("model_id ~ ?", '\d{8}') }
  scope :for_provider, ->(provider) { where(provider: provider) }

  scope :available_for_user, ->(user) {
    providers = user.api_keys.pluck(:provider).uniq
    return none if providers.empty?

    allowed_model_ids = providers.flat_map { |p| ALLOWED_MODELS[p] || [] }
    return none if allowed_model_ids.empty?

    where(provider: providers)
      .without_dated_versions
      .where(model_id: allowed_model_ids)
  }
end
