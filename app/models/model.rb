class Model < ApplicationRecord
  has_many :chats

  ALLOWED_MODELS = {
    "anthropic" => %w[claude-opus-4-1 claude-sonnet-4-5 claude-haiku-4-5],
    #"gemini" => %w[gemini-2.5-flash gemini-2.5-flash-lite gemini-2.5-pro],
    #"openai" => %w[gpt-5 gpt-5-mini gpt-5-nano gpt-5-pro]
  }.freeze

  validates :provider, presence: true
  validates :model_id, presence: true, uniqueness: { scope: :provider }
  validates :name, presence: true

  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :available_for_user, ->(user) {
    providers = user.api_keys.pluck(:provider).uniq
    return none if providers.empty?
    where(provider: providers).where(model_id: ALLOWED_MODELS.values.flatten)
  }
end
