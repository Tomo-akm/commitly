class RepliesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [ :create ]
  before_action :set_reply, only: [ :destroy ]

  def create
    # 投稿に対する直接のリプライ
    @reply = @post.replies.build(reply_params)
    @reply.user = current_user

    # # 任意: リプライへのリプライの場合 (ルーティング追加が必要)
    # if params[:reply_id]
    #   @parent_reply = Reply.find(params[:reply_id])
    #   @reply.parent = @parent_reply
    #   @reply.post = @parent_reply.post # 親リプライと同じ投稿に関連付ける
    # end

    if @reply.save
      # Turbo Stream を使って非同期にリプライを追加する場合
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post, notice: "リプライを送信しました。" }
      end
    else
      # エラー処理 (例: Turbo Stream でフォームを再描画)
      respond_to do |format|
        format.turbo_stream do
           render turbo_stream: turbo_stream.replace(
             "reply_form_post_#{@post.id}", # フォームのIDを指定
             partial: "replies/form",
             locals: { post: @post, reply: @reply }
           ), status: :unprocessable_entity
        end
        format.html do
          # エラーメッセージを表示して投稿詳細ページにリダイレクトなど
          flash.now[:alert] = @reply.errors.full_messages.join(", ")
          # 詳細ページを再描画するために必要なデータを取得
          @replies = @post.replies.where(parent_id: nil).includes(:user).order(created_at: :desc) # トップレベルリプライのみ取得
          render "posts/show", status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    if @reply.user == current_user
      @reply.destroy
      respond_to do |format|
        # Turbo Stream を使って非同期にリプライを削除
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@reply) }
        format.html { redirect_to @reply.post, notice: "返信を削除しました。", status: :see_other }
      end
    else
      redirect_to @reply.post, alert: "返信の削除権限がありません。", status: :forbidden
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_reply
    # params[:id] は replies/:id ルートから来る
    # params[:post_id] は posts/:post_id/replies/:id ルートから来る
    reply_id = params[:id]
    @reply = Reply.find(reply_id)
  end

  def reply_params
    params.require(:reply).permit(:content, :parent_id) # parent_idも許可
  end
end
