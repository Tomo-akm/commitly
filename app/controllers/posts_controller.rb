class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :check_post_ownership, only: %i[ edit update destroy ]

  # GET /posts or /posts.json
  def index
    @q = Post.top_level.visible_to(current_user).ransack(params[:q])  # リプライを除外し、公開範囲フィルタを適用
    @posts = @q.result(distinct: true)
            .preload(:contentable, :likes, :user, :tags, :replies)  # N+1対策（preloadを使用してポリモーフィック関連に対応）
            .order(created_at: :desc)
            .page(params[:page])
            .per(10)

    # サイドバー用のタグ一覧（tags#showと同じロジック: visible_to(current_user)でカウント）
    visible_post_ids = Post.visible_to(current_user).pluck(:id)
    @popular_tags = Tag.joins(:posts)
                       .where(posts: { id: visible_post_ids })
                       .group("tags.id")
                       .select("tags.*, COUNT(posts.id) AS visible_posts_count")
                       .order("COUNT(posts.id) DESC")
                       .limit(10)
  end

  # GET /posts/1 or /posts/1.json
  def show
    # 投稿の可視性チェック
    unless @post.visible_to?(current_user)
      redirect_to posts_path, alert: "この投稿を閲覧する権限がありません。" and return
    end
  end

  # GET /posts/new
  def new
    # リプライの場合は強制的にGeneralContentに
    type = params[:parent_id].present? ? "general" : params[:type]
    @post = current_user.posts.build_with_type(type)
    @post.parent_id = params[:parent_id]
  end

  # GET /posts/1/edit
  def edit
    # @postが既にset_postで設定されているため、追加の処理は不要
  end

  # POST /posts or /posts.json
  def create
    parent_id = params.dig(:post, :parent_id)

    if parent_id.present?
      create_reply(parent_id)
    else
      create_post
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    if @post.update_with_form_params(contentable_params, params[:post] || {})
      redirect_to @post, notice: "コミットをmergeしました✨", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @message = "コミットをrevertしました"
    @post.destroy!
    # Refererから現在表示中の投稿IDを取得
    @viewing_post_id = request.referer&.match(/\/posts\/(\d+)/)&.[](1)&.to_i

    # 表示中の投稿を削除した場合はリダイレクト
    if @viewing_post_id == @post.id
      redirect_to posts_path, notice: @message, status: :see_other
      return
    end

    # リプライ削除はTurbo Streamで部分更新
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to posts_path, notice: "コミットをrevertしました↩️", status: :see_other }
    end
  end

  private
    # リプライ作成処理
    def create_reply(parent_id)
      unless Post.exists?(parent_id)
        flash.now[:alert] = "指定された親投稿が見つかりません。"
        @post = current_user.posts.build_with_type("general")
        render :new, status: :unprocessable_entity
        return
      end

      @post = current_user.posts.build_with_type("general")
      @post.parent_id = parent_id

      if @post.update_with_form_params(contentable_params, params[:post] || {})
        redirect_to post_path(@post.parent), notice: @post.contentable.success_message
      else
        flash.now[:alert] = "入力内容に誤りがあります。確認してください。"
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::InvalidForeignKey
      flash.now[:alert] = "指定された親投稿が見つかりません。"
      render :new, status: :unprocessable_entity
    end

    # 通常投稿作成処理
    def create_post
      @post = current_user.posts.build_with_type(params[:type])

      if @post.update_with_form_params(contentable_params, params[:post] || {})
        redirect_to posts_path, notice: @post.contentable.success_message
      else
        flash.now[:alert] = "入力内容に誤りがあります。確認してください。"
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::InvalidForeignKey
      flash.now[:alert] = "投稿の作成中にエラーが発生しました。"
      render :new, status: :unprocessable_entity
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.includes(:contentable, :parent, replies: [ :contentable, :user, :tags, :likes ]).find(params.expect(:id))
    end

    # Check if the current user owns the post
    def check_post_ownership
      unless @post.user == current_user
        redirect_to @post, alert: "このコミットをrebase・revertする権限がありません。"
      end
    end

    # contentable の型に応じてパラメータを返す
    def contentable_params
      if @post.general?
        params.expect(general_content: [ :content ])
      elsif @post.job_hunting?
        params.expect(job_hunting_content: [ :company_name, :selection_stage, :result, :content ])
      end
    end
end
