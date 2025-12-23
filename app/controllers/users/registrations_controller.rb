# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # POST /resource
  def create
    build_resource(sign_up_params)
    resource.save

    if resource.persisted?
      flash[:notice] = "アカウントを作成しました。ようこそ！"

      if resource.active_for_authentication?
        sign_up(resource_name, resource)
        redirect_to after_sign_up_path_for(resource)
      else
        expire_data_after_sign_in!
        redirect_to after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords(resource)
      flash[:alert] = "入力内容に誤りがあります。"
      redirect_to new_user_registration_path
    end
  end
end
