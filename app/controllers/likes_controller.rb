class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @like = @post.likes.build(user: current_user)

    if @like.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "like_button_#{@post.id}",
            partial: "shared/like_button",
            locals: { post: @post }
          )
        end
        format.html { redirect_to @post }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @like = @post.likes.find(params[:id])

    if @like.user_id == current_user.id
      @like.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "like_button_#{@post.id}",
            partial: "shared/like_button",
            locals: { post: @post }
          )
        end
        format.html { redirect_to @post }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
