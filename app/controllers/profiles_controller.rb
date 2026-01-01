class ProfilesController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :following, :followers ]
  before_action :set_user, only: [ :show, :likes, :following, :followers ]
  before_action :set_right_nav_data, only: [ :show, :likes, :following, :followers ]

  def show
    @posts = @user.posts.visible_to(current_user).preload(:contentable, :user, :likes, :tags).order(created_at: :desc).page(params[:page]).per(POSTS_PER_PAGE)
    prepare_heatmap_data
    # プロフィールの投稿・ヒートマップの可視性判定
    @posts_visible = posts_visible_to_viewer?
  end

  def likes
    @liked_posts = @user.liked_posts
                        .visible_to(current_user)
                        .preload(:contentable, :user, :tags, :likes)
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(POSTS_PER_PAGE)
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
    redirect_to user_profile_path(@user.account_id), notice: "プロフィールを更新しました。"
  rescue ActiveRecord::RecordInvalid
    # バリデーション失敗時、アバターをDBの状態に戻す（古い画像を復元）
    @user.avatar.reload if @user.avatar.attached?
    render :edit, status: :unprocessable_entity
  end

  def following
    @follow_list_visible = follow_list_visible_to_viewer?
    @users = @follow_list_visible ? @user.following : []
    render "show_follow"
  end

  def followers
    @follow_list_visible = follow_list_visible_to_viewer?
    @users = @follow_list_visible ? @user.followers : []
    render "show_follow"
  end

  private

  def set_user
    @user = User.find_by!(account_id: params[:account_id])
  end

  def profile_params
    params.expect(user: [ :name, :favorite_language, :internship_count, :personal_message, :graduation_year, :avatar ])
  end

  def prepare_heatmap_data
    @date = Date.current
    @date_6_months_ago = 6.months.ago.to_date

    posts_by_day = @user.posts
                         .visible_to(current_user)
                         .where(created_at: heatmap_date_range)
                         .group_by_day(:created_at, range: @date_6_months_ago..@date, format: "%Y-%m-%d", time_zone: Time.zone)
                         .count

    entry_sheet_scope = @user.entry_sheets
    if @user != current_user
      if @user.content_visible_to?(current_user)
        entry_sheet_scope = entry_sheet_scope.publicly_visible
      else
        entry_sheet_scope = entry_sheet_scope.none
      end
    end

    entry_sheets_by_day = entry_sheet_scope
                           .where(updated_at: heatmap_date_range)
                           .group_by_day(:updated_at, range: @date_6_months_ago..@date, format: "%Y-%m-%d", time_zone: Time.zone)
                           .count

    templates_scope = @user.entry_sheet_item_templates
    templates_scope = templates_scope.none unless @user == current_user || @user.content_visible_to?(current_user)

    templates_by_day = templates_scope
                        .where(updated_at: heatmap_date_range)
                        .group_by_day(:updated_at, range: @date_6_months_ago..@date, format: "%Y-%m-%d", time_zone: Time.zone)
                        .count

    combined_counts = Hash.new(0)
    posts_by_day.each { |date, count| combined_counts[date] += count }
    entry_sheets_by_day.each { |date, count| combined_counts[date] += count }
    templates_by_day.each { |date, count| combined_counts[date] += count }

    @active_user_counts_6_months = combined_counts.map { |date, count| [ date, count ] }
    @activity_summary = @user.activity_summary_from_counts(combined_counts)
    @achievement_flags = @user.achievement_flags
    @achievement_history = @user.achievement_history
  end

  def heatmap_date_range
    @date_6_months_ago.beginning_of_day..@date.end_of_day
  end

  # 投稿・ヒートマップの可視性判定
  def posts_visible_to_viewer?
    return true if @user == current_user # 本人は常に見える
    return true if @user.everyone? # 全体公開は誰でも見える
    return true if @user.mutual_followers? && current_user&.mutual_follow?(@user) # 相互フォローのみ

    false # それ以外は見えない
  end

  # フォローリストの可視性判定
  def follow_list_visible_to_viewer?
    return true if @user == current_user # 本人は常に見える
    return true if @user.everyone? # 全体公開は誰でも見える（ログアウト時も含む）
    return true if @user.mutual_followers? && current_user&.mutual_follow?(@user) # 相互フォローのみ

    false # それ以外は見えない
  end
end
