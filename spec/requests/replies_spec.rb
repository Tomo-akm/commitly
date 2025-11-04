require 'rails_helper'

RSpec.describe "Replies", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post_record) { create(:post, user: user) } # 投稿（post）は 'post' という名前のファクトリから作成

  # --- ログイン処理 ---
  before do
    sign_in user, scope: :user
  end

  # --- リプライ作成（POST）のテスト ---
  describe "POST /posts/:post_id/replies" do
    let(:valid_attributes) { { reply: { content: "これはリプライです" } } }
    let(:invalid_attributes) { { reply: { content: "" } } } # 空のリプライ

    context "with valid parameters" do
      it "creates a new Reply" do
        expect {
          # Turbo Streamとしてリクエストを送信
          post post_replies_path(post_record), params: valid_attributes, as: :turbo_stream
        }.to change(Reply, :count).by(1)
      end

      it "renders a successful response (turbo_stream)" do
        post post_replies_path(post_record), params: valid_attributes, as: :turbo_stream
        expect(response).to be_successful
        expect(response.media_type).to eq Mime[:turbo_stream]
      end
    end

    context "with invalid parameters" do
      it "does not create a new Reply" do
        expect {
          post post_replies_path(post_record), params: invalid_attributes, as: :turbo_stream
        }.to change(Reply, :count).by(0)
      end

      it "renders an unprocessable entity response (turbo_stream)" do
        post post_replies_path(post_record), params: invalid_attributes, as: :turbo_stream
        # 以前の警告(unprocessable_entity)に対応し、:unprocessable_content を使用
        expect(response).to have_http_status(:unprocessable_content) 
        expect(response.media_type).to eq Mime[:turbo_stream]
      end
    end

    context "when not logged in" do
      before { sign_out user } # ログアウト
      it "redirects to login page" do
         post post_replies_path(post_record), params: valid_attributes
         expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # --- リプライ削除（DELETE）のテスト ---
  describe "DELETE /posts/:post_id/replies/:id" do
    let!(:reply) { create(:reply, post: post_record, user: user) }
    let!(:other_reply) { create(:reply, post: post_record, user: other_user) } # 他人のリプライ

    context "when deleting own reply" do
      it "destroys the requested reply" do
        expect {
          delete post_reply_path(post_record, reply), as: :turbo_stream
        }.to change(Reply, :count).by(-1)
      end

      it "renders a successful response (turbo_stream)" do
        delete post_reply_path(post_record, reply), as: :turbo_stream
        expect(response).to be_successful
        expect(response.media_type).to eq Mime[:turbo_stream]
      end
    end

    context "when trying to delete other user's reply" do
      it "does not destroy the reply" do
        expect {
          delete post_reply_path(post_record, other_reply), as: :turbo_stream
        }.to change(Reply, :count).by(0)
      end

       it "redirects or renders forbidden status" do
        delete post_reply_path(post_record, other_reply) # HTMLリクエストとしてテスト
        expect(response).to have_http_status(:forbidden) # 403 Forbidden
      end
    end

    context "when not logged in" do
      before { sign_out user } # ログアウト
      it "redirects to login page" do
         delete post_reply_path(post_record, reply)
         expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end