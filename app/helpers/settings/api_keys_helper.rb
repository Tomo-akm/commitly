module Settings
  module ApiKeysHelper
    # APIキーをマスク表示する
    # 例: "sk-ant-abc123..." -> "sk-ant-***...***123"
    def mask_api_key(api_key)
      return "" if api_key.blank?

      # 最初の7文字と最後の3文字を表示
      if api_key.length > 10
        "#{api_key[0..6]}***...***#{api_key[-3..-1]}"
      else
        "***"
      end
    end
  end
end
