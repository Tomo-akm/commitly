class ProfilesController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :set_user, only: [ :show, :likes ]

  def show
    @posts = @user.posts.includes(:contentable, :user, :likes, :tags).order(created_at: :desc)
    prepare_heatmap_data
  end

  def likes
    @liked_posts = current_user.liked_posts.includes(:contentable, :user, :tags, :likes).order(created_at: :desc)
    prepare_heatmap_data
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # アバター削除の処理（Turbo Streamで部分更新）
    if params[:avatar_purge] == "true"
      @user.avatar.purge
      respond_to do |format|
        format.turbo_stream { render "profiles/avatar_delete" }
        format.html { redirect_to edit_profile_path, notice: "アバター画像を削除しました。" }
      end
      return
    end

    @user.update!(profile_params)
    redirect_to profile_path, notice: "プロフィールを更新しました。"
  rescue ActiveRecord::RecordInvalid
    # バリデーション失敗時、アバターをDBの状態に戻す（古い画像を復元）
    @user.avatar.reload if @user.avatar.attached?
    render :edit, status: :unprocessable_entity
  end

  def following
    @user  = User.find(params[:id])
    @users = @user.following
    render "show_follow"
  end

  def followers
    @user  = User.find(params[:id])
    @users = @user.followers
    render "show_follow"
  end

  private

  def set_user
    @user = params[:id] ? User.find(params[:id]) : current_user
  end

  def profile_params
    params.expect(user: [ :name, :favorite_language, :internship_count, :personal_message, :avatar ])
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
