RubyLLM.configure do |config|
  # ユーザーごとにAPIキーを動的に設定するため、ここでは設定しない
  # APIキーはChatResponseJobなどで各ユーザーのapi_keysテーブルから動的にロードする

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
