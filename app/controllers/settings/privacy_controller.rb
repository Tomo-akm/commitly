# frozen_string_literal: true

module Settings
  class PrivacyController < ApplicationController
    before_action :authenticate_user!

    def show
      # プライバシー設定の表示
    end

    def update
      if current_user.update(privacy_params)
        redirect_to settings_privacy_path, notice: "プライバシー設定を更新しました"
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def privacy_params
      params.expect(user: [ :post_visibility ])
    end
  end
end