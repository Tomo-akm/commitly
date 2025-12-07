module Settings
  class ApiKeysController < ApplicationController
    before_action :authenticate_user!

    def index
      @api_keys = current_user.api_keys.sort_by do |key|
        ApiKey::PROVIDERS.index(key.provider)
      end
      @api_key = ApiKey.new
    end

    def create
      @api_key = current_user.api_keys.build(api_key_params)

      if @api_key.save
        redirect_to settings_api_keys_path, notice: "APIキーを登録しました"
      else
        redirect_to settings_api_keys_path, alert: @api_key.errors.full_messages.first
      end
    end

    def destroy
      @api_key = current_user.api_keys.find(params[:id])
      @api_key.destroy!

      redirect_to settings_api_keys_path, notice: "APIキーを削除しました"
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to settings_api_keys_path, alert: "APIキーの削除に失敗しました"
    end

    private

    def api_key_params
      params.expect(api_key: [ :provider, :api_key ])
    end
  end
end
