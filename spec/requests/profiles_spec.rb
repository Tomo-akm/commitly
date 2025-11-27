require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:liked_post) { create(:post, user: other_user) }
  let!(:other_post) { create(:post, user: other_user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /profile/edit" do
    it "編集ページにアクセスできる" do
      get edit_profile_path
      expect(response).to have_http_status(:success)
    end

    it "名前フィールドが表示される" do
      get edit_profile_path
      expect(response.body).to include('id="user_name"')
    end
  end

  describe "PATCH /profile" do
    context "有効なパラメータの場合" do
      it "名前を更新できる" do
        patch profile_path, params: {
          user: {
            name: "新しい名前"
          }
        }
        user.reload
        expect(user.name).to eq("新しい名前")
      end

      it "プロフィール情報を更新できる" do
        patch profile_path, params: {
          user: {
            name: "新しい名前",
            favorite_language: "Ruby",
            research_lab: "情報工学研究室",
            internship_count: 5,
            personal_message: "よろしくお願いします"
          }
        }
        user.reload
        expect(user.name).to eq("新しい名前")
        expect(user.favorite_language).to eq("Ruby")
        expect(user.research_lab).to eq("情報工学研究室")
        expect(user.internship_count).to eq(5)
        expect(user.personal_message).to eq("よろしくお願いします")
      end

      it "更新後にプロフィールページにリダイレクトする" do
        patch profile_path, params: {
          user: {
            name: "新しい名前"
          }
        }
        expect(response).to redirect_to(profile_path)
      end

      it "成功メッセージが表示される" do
        patch profile_path, params: {
          user: {
            name: "新しい名前"
          }
        }
        follow_redirect!
        expect(response.body).to include("プロフィールを更新しました。")
      end
    end

    context "無効なパラメータの場合" do
      it "名前が空の場合は更新できない" do
        old_name = user.name
        patch profile_path, params: {
          user: {
            name: ""
          }
        }
        user.reload
        expect(user.name).to eq(old_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

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

    context "未ログイン" do
      it "ログインページにリダイレクト" do
        sign_out user
        get profile_likes_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
