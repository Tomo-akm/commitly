class ApiKey < ApplicationRecord
  belongs_to :user

  encrypts :api_key

  PROVIDERS = %w[openai anthropic gemini].freeze

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: :user_id, message: "は既に登録されています" }
  validates :api_key, presence: true

  scope :for_provider, ->(provider) { where(provider: provider) }
end