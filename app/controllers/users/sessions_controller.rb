# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Devise のデフォルト実装を使用
  # flash メッセージは config/locales/devise.ja.yml で設定
end
