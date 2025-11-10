class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :check_post_ownership, only: %i[ edit update destroy ]

  # GET /posts or /posts.json
  def index
    @q = Post.top_level.ransack(params[:q])  # リプライを除外
    @posts = @q.result(distinct: true)
            .includes(:contentable, :likes, :user, :tags, :replies)  # N+1対策（repliesも追加）
            .order(created_at: :desc)
            .page(params[:page])
            .per(10)

    # サイドバー用のタグ一覧（投稿数上位10個）
    @popular_tags = Tag.with_posts.popular.limit(10)
  end

  # GET /posts/1 or /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    # リプライの場合は強制的にGeneralContentに
    type = params[:parent_id].present? ? "general" : params[:type]
    @post = current_user.posts.build_with_type(type)
    @post.parent_id = params[:parent_id] if params[:parent_id].present?
  end

  # GET /posts/1/edit
  def edit
    # @postが既にset_postで設定されているため、追加の処理は不要
  end

  # POST /posts or /posts.json
  def create
    # リプライの場合は強制的にGeneralContentに
    is_reply = params.dig(:post, :parent_id).present?
    type = is_reply ? "general" : params[:type]
    @post = current_user.posts.build_with_type(type)

    # リプライの場合、parent_idを設定
    @post.parent_id = params.dig(:post, :parent_id) if is_reply

    if @post.update_with_form_params(contentable_params, params[:post] || {})
      # リプライの場合は親投稿のshowページにリダイレクト
      redirect_url = is_reply ? post_path(@post.parent) : posts_path
      redirect_to redirect_url, notice: @post.contentable.success_message
    else
      flash.now[:alert] = "入力内容に誤りがあります。確認してください。"
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::InvalidForeignKey
    flash.now[:alert] = "指定された投稿が見つかりません。"
    render :new, status: :unprocessable_entity
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
    @post.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to posts_path, notice: "コミットをrevertしました↩️", status: :see_other }
    end
  end

  private
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
