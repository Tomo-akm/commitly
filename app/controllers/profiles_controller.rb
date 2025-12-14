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
    if params[:avatar_purge] == 'true'
      @user.avatar.purge
      respond_to do |format|
        format.turbo_stream { render "profiles/avatar_delete" }
        format.html { redirect_to edit_profile_path, notice: "アバター画像を削除しました。" }
      end
      return
    end

    # アバター画像の事前バリデーション
    return unless validate_avatar_before_update

    if @user.update(profile_params)
      redirect_to profile_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
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
    params.require(:user).permit(:name, :favorite_language, :research_lab, :internship_count, :personal_message, :avatar)
  end

  # アバター画像の事前バリデーション（image_processingエラーを防ぐ）
  def validate_avatar_before_update
    return true unless params[:user]&.dig(:avatar).present?

    avatar_file = params[:user][:avatar]

    # ファイル形式チェック
    allowed_types = %w[image/png image/jpeg]
    unless allowed_types.include?(avatar_file.content_type)
      @user.errors.add(:avatar, "はPNGまたはJPEG形式のみアップロードできます")
      render :edit, status: :unprocessable_entity
      return false
    end

    # ファイルサイズチェック（5MB制限）
    max_size = 5.megabytes
    if avatar_file.size > max_size
      @user.errors.add(:avatar, "は5MB未満にしてください")
      render :edit, status: :unprocessable_entity
      return false
    end

    true
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
