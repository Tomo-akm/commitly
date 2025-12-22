class TagsController < ApplicationController
  before_action :set_right_nav_data, only: %i[index show]

  def index
    @q = Tag.ransack(params[:q])
    @tags = @q.result(distinct: true).with_posts.popular.page(params[:page]).per(20)
  end

  def show
    @tag = Tag.find(params[:id])
    @q = @tag.posts.visible_to(current_user).ransack(params[:q])
    @posts = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(10)
    # 可視性フィルタを適用した投稿数
    @visible_posts_count = @tag.posts.visible_to(current_user).count
  end

  def autocomplete
    q = params[:q].to_s

    tags = Tag
      .where("name ILIKE ?", "#{q}%")
      .order(posts_count: :desc)
      .limit(10)
      .pluck(:name, :posts_count)
      .map { |name, count| { name:, posts_count: count } }

    render json: tags
  end
end
