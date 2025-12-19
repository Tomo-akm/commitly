# frozen_string_literal: true

module Settings
  class SettingsController < ApplicationController
    before_action :authenticate_user!

    def index
      # 設定のハブページ（サイドバーで各設定項目を選択）
    end
  end
end
