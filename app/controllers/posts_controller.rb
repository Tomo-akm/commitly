class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :check_post_ownership, only: %i[ edit update destroy ]

  # GET /posts or /posts.json
  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true)
            .includes(:contentable, :likes, :user, :tags)  # N+1対策（contentable追加）
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
    @post = Post.new
    @post_type = params[:type] || "general"

    if @post_type == "job_hunting"
      @job_hunting_content = JobHuntingContent.new
    else
      @general_content = GeneralContent.new
    end
  end

  # GET /posts/1/edit
  def edit
    # contentable の型に応じてインスタンス変数を設定
    if @post.general?
      @general_content = @post.contentable
    elsif @post.job_hunting?
      @job_hunting_content = @post.contentable
    end
  end

  # POST /posts or /posts.json
  def create
    @post_type = params[:type] || "general"

    if @post_type == "job_hunting"
      @job_hunting_content = JobHuntingContent.new(job_hunting_content_params)
      @post = current_user.posts.build(contentable: @job_hunting_content)
      success_message = "就活記録をpushしました"
    else
      @general_content = GeneralContent.new(general_content_params)
      @post = current_user.posts.build(contentable: @general_content)
      # タグの設定（通常投稿のみ）
      @post.tag_names = params.dig(:post, :tag_names) if params.dig(:post, :tag_names).present?
      success_message = "つぶやきをpushしました"
    end

    if @post.save
      redirect_to posts_path, notice: success_message
    else
      flash.now[:alert] = "入力内容に誤りがあります。確認してください。"
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    # contentable の型に応じてインスタンス変数を設定
    if @post.general?
      @general_content = @post.contentable
      # 通常投稿のみタグを更新
      @post.tag_names = params.dig(:post, :tag_names) if params.dig(:post, :tag_names).present?
    elsif @post.job_hunting?
      @job_hunting_content = @post.contentable
    end

    # contentableとpostの両方を保存（トランザクション内で）
    ActiveRecord::Base.transaction do
      @post.contentable.update!(contentable_params)
      @post.save!  # after_commitコールバックを発火させる
    end

    redirect_to @post, notice: "コミットをmergeしました✨", status: :see_other
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!
    redirect_to posts_path, notice: "コミットをrevertしました↩️", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.includes(:contentable).find(params.expect(:id))
    end

    # Check if the current user owns the post
    def check_post_ownership
      unless @post.user == current_user
        redirect_to @post, alert: "このコミットをrebase・revertする権限がありません。"
      end
    end

    # 通常投稿用のパラメータ
    def general_content_params
      params.expect(general_content: [ :content ])
    end

    # 就活投稿用のパラメータ
    def job_hunting_content_params
      params.expect(job_hunting_content: [ :company_name, :selection_stage, :result, :content ])
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
