# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # POST /resource
  def create
    super do |resource|
      if resource.persisted?
        flash[:notice] = "アカウントを作成しました。ログインしています..."
      end
    end
  end
end
