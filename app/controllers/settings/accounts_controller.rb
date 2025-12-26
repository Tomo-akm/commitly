# frozen_string_literal: true

module Settings
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def show
    end

    def update
      # パスワードユーザー（provider.blank?）の場合のみパスワード検証
      if current_user.provider.blank? && (params[:user][:current_password].blank? || !current_user.valid_password?(params[:user][:current_password]))
        current_user.errors.add(:current_password, "が正しくありません")
        render :show, status: :unprocessable_entity
        return
      end

      if current_user.update(account_params)
        # email変更の場合は再ログイン不要（bypass_sign_in）
        bypass_sign_in(current_user) if account_params[:email].present?
        redirect_to settings_account_path, notice: "アカウント情報を更新しました"
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def account_params
      params.expect(user: [ :account_id, :email ])
    end
  end
end
