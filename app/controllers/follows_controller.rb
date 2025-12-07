class FollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    @user = User.find(params[:user_id])
    follow_result = current_user.follow(@user)

    respond_to do |format|
      if follow_result
        @user.reload  # フォロワー数を最新にする
        format.html { redirect_back fallback_location: root_path, notice: "フォローしました" }
        format.turbo_stream
      else
        format.html { redirect_back fallback_location: root_path, alert: "フォローできませんでした" }
        format.turbo_stream { render turbo_stream: turbo_stream.update("alert", partial: "shared/alert", locals: { message: "フォローできませんでした" }) }
      end
    end
  end

  def destroy
    follow = current_user.active_follows.find_by(id: params[:id])
    @user = follow&.followed  # フォローされているユーザーを取得
    follow&.destroy
    @user&.reload  # フォロワー数を最新にする

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, status: :see_other, notice: "フォローを解除しました" }
      format.turbo_stream
    end
  end
end
