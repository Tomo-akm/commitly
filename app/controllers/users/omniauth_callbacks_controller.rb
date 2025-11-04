# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  SUCCESS_MESSAGE = "Googleアカウントでログインしました"
  FAILURE_MESSAGE = "Google認証に失敗しました。もう一度お試しください"

  def google_oauth2
    auth = request.env["omniauth.auth"]

    @user = User.from_omniauth(auth)

    if @user.persisted?
      handle_success
    else
      handle_creation_failure
    end
  end

  def failure
    flash[:alert] = FAILURE_MESSAGE
    redirect_to new_user_session_path
  end

  private

  def handle_success
    sign_in_and_redirect @user, event: :authentication
    flash[:notice] = SUCCESS_MESSAGE
  end

  def handle_creation_failure
    flash[:alert] = "アカウントの作成に失敗しました: #{@user.errors.full_messages.join(', ')}"
    session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
    redirect_to new_user_registration_url
  end
end
