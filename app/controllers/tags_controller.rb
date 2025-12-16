class TagsController < ApplicationController
  def index
    @q = Tag.ransack(params[:q])
    @tags = @q.result(distinct: true).with_posts.popular.page(params[:page]).per(20)
  end

  def show
    @tag = Tag.find(params[:id])
    @q = @tag.posts.ransack(params[:q])
    @posts = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(10)
  end

  def autocomplete
    q = params[:q].to_s

    tags = Tag
      .where("name ILIKE ?", "#{q}%")
      .order(posts_count: :desc)
      .limit(10)
      .pluck(:name)

    render json: tags
  end
end
