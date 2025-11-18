class FollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    @user = User.find(params[:user_id])
    current_user.follow(@user)
    redirect_back(fallback_location: root_path)
  end

  def destroy
    follow = Follow.find(params[:id])
    if current_user.id == follow.follower_id
      follow.destroy
    end
    redirect_back(fallback_location: root_path)
  end
end
