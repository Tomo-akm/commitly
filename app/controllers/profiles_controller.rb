class ProfilesController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  def show
    @user = params[:id] ? User.find(params[:id]) : (current_user if user_signed_in?)
    @posts = @user.posts
                  .includes(:contentable, :likes, :tags)
                  .order(created_at: :desc)
    prepare_heatmap_data
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:favorite_language, :research_lab, :internship_count, :personal_message)
  end

  def prepare_heatmap_data
    @date = Date.current
    @date_6_months_ago = 6.months.ago.to_date

    @active_user_counts_6_months = @user.posts
                                         .where(created_at: heatmap_date_range)
                                         .group_by_day(:created_at, range: @date_6_months_ago..@date, format: "%Y-%m-%d")
                                         .count
                                         .map { |date, count| [ date, count ] }
  end

  def heatmap_date_range
    @date_6_months_ago.beginning_of_day..@date.end_of_day
  end
end
