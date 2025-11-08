# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:liked_post) { create(:post, user: other_user) }
  let!(:other_post) { create(:post, user: other_user) }

  describe "GET /profile/likes" do
    context "ログイン済み" do
      before { sign_in user, scope: :user }

      it "いいねした投稿のみ表示される" do
        create(:like, user: user, post: liked_post)
        get profile_likes_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(liked_post.content)
        expect(response.body).not_to include(other_post.content)
      end

      it "いいねがない場合、メッセージが表示される" do
        get profile_likes_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("まだいいねした投稿がありません")
      end
    end

    it "未ログインの場合、ログインページにリダイレクト" do
      get profile_likes_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /users/:id/profile/likes" do
    before { sign_in user, scope: :user }

    it "他ユーザーのいいね一覧はアクセス不可" do
      get user_profile_likes_path(other_user)

      expect(response).to redirect_to(user_profile_path(other_user))
      follow_redirect!
      expect(response.body).to include("他のユーザーのいいね一覧は閲覧できません")
    end

    it "自分のいいね一覧は閲覧可能" do
      create(:like, user: user, post: liked_post)
      get user_profile_likes_path(user)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(liked_post.content)
    end
  end
end
