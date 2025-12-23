# frozen_string_literal: true

module Settings
  class SettingsController < ApplicationController
    before_action :authenticate_user!

    def index
      redirect_to Settings::Navigation.default_path
    end
  end
end
