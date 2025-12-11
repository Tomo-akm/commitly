require 'rails_helper'

RSpec.describe "Stars", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }

  before do
    sign_in user, scope: :user
  end

  describe "POST /posts/:post_id/likes" do
    context "Starが作成される場合" do
      it "Like数が1増える" do
        expect {
          post post_likes_path(post_record)
        }.to change(Like, :count).by(1)
      end

      it "作成されたStarのuser_idとpost_idが正しい" do
        post post_likes_path(post_record)
        like = Like.last
        expect(like.user_id).to eq(user.id)
        expect(like.post_id).to eq(post_record.id)
      end
    end

    context "重複Starの場合" do
      let!(:existing_like) { create(:like, user: user, post: post_record) }

      it "Like数が増えない" do
        expect {
          post post_likes_path(post_record)
        }.not_to change(Like, :count)
      end

      it "422ステータスが返される" do
        post post_likes_path(post_record)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /posts/:post_id/likes/:id" do
    let!(:like) { create(:like, user: user, post: post_record) }

    context "Starが削除される場合" do
      it "Like数が1減る" do
        expect {
          delete post_like_path(post_record, like)
        }.to change(Like, :count).by(-1)
      end
    end

    context "他人のStarを削除しようとする場合" do
      let(:other_user) { create(:user) }
      let!(:other_like) { create(:like, user: other_user, post: post_record) }

      it "Like数が減らない" do
        expect {
          delete post_like_path(post_record, other_like)
        }.not_to change(Like, :count)
      end

      it "422ステータスが返される" do
        delete post_like_path(post_record, other_like)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "認証なしでのアクセス" do
    before do
      sign_out user
    end

    context "POST /posts/:post_id/likes" do
      it "リダイレクトされる" do
        post post_likes_path(post_record)
        expect(response).to have_http_status(:redirect)
      end

      it "Like数が増えない" do
        expect {
          post post_likes_path(post_record)
        }.not_to change(Like, :count)
      end
    end

    context "DELETE /posts/:post_id/likes/:id" do
      let!(:like) { create(:like, user: user, post: post_record) }

      it "リダイレクトされる" do
        delete post_like_path(post_record, like)
        expect(response).to have_http_status(:redirect)
      end

      it "Like数が減らない" do
        expect {
          delete post_like_path(post_record, like)
        }.not_to change(Like, :count)
      end
    end
  end
end
