# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    if successfully_sent?(resource)
      redirect_to after_sending_reset_password_instructions_path_for(resource_name)
    else
      flash[:alert] = "メールアドレスを確認してください。"
      redirect_to new_user_password_path
    end
  end
end
