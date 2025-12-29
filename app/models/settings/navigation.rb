# frozen_string_literal: true

module Settings
  module Navigation
    Tab = Struct.new(:label, :path, :icon, :key, keyword_init: true)

    TAB_DEFINITIONS = [
      { label: "アカウント", path: :settings_account_path, icon: "fas fa-user-cog", key: :account },
      { label: "プライバシー", path: :settings_privacy_path, icon: "fas fa-lock", key: :privacy }
    ].freeze

    def self.tabs(view_context)
      TAB_DEFINITIONS.map do |definition|
        Tab.new(
          label: definition[:label],
          path: view_context.public_send(definition[:path]),
          icon: definition[:icon],
          key: definition[:key]
        )
      end
    end

    def self.default_path
      first_path = TAB_DEFINITIONS.first[:path]
      Rails.application.routes.url_helpers.public_send(first_path)
    end
  end
end
