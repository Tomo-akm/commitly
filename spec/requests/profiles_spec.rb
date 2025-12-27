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
            internship_count: 5,
            personal_message: "よろしくお願いします"
          }
        }
        user.reload
        expect(user.name).to eq("新しい名前")
        expect(user.favorite_language).to eq("Ruby")
        expect(user.internship_count).to eq(5)
        expect(user.personal_message).to eq("よろしくお願いします")
      end

      it "卒業年度を更新できる" do
        patch profile_path, params: {
          user: {
            name: user.name,
            graduation_year: 2026
          }
        }
        user.reload
        expect(user.graduation_year).to eq(2026)
      end

      it "更新後にプロフィールページにリダイレクトする" do
        patch profile_path, params: {
          user: {
            name: "新しい名前"
          }
        }
        expect(response).to redirect_to(user_profile_path(user.account_id))
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

      it "卒業年度が2000年未満の場合は更新できない" do
        patch profile_path, params: {
          user: {
            name: user.name,
            graduation_year: 1999
          }
        }
        user.reload
        expect(user.graduation_year).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "卒業年度が2100年を超える場合は更新できない" do
        patch profile_path, params: {
          user: {
            name: user.name,
            graduation_year: 2101
          }
        }
        user.reload
        expect(user.graduation_year).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /profile/likes" do
    context "ログイン済み" do
      before { sign_in user, scope: :user }

      it "Starした投稿のみ表示される" do
        create(:like, user: user, post: liked_post)
        get user_profile_likes_path(user.account_id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(liked_post.content)
        expect(response.body).not_to include(other_post.content)
      end

      it "Starがない場合、メッセージが表示される" do
        get user_profile_likes_path(user.account_id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("まだStarした投稿がありません")
      end
    end

    context "未ログイン" do
      it "ログインページにリダイレクト" do
        sign_out user
        get user_profile_likes_path(user.account_id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "公開範囲機能" do
    describe "GET /users/:id (プロフィールページの表示制御)" do
      let!(:viewer) { create(:user) }
      let!(:profile_owner) { create(:user, post_visibility: :everyone) }
      let!(:post1) { create(:post, user: profile_owner) }
      let!(:post2) { create(:post, user: profile_owner) }

      before do
        sign_in viewer
      end

      context '全体公開の場合' do
        it '投稿とヒートマップが表示される' do
          get user_profile_path(profile_owner.account_id)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(post1.contentable.content)
          expect(response.body).to include(post2.contentable.content)
          expect(response.body).to include('heatmap') # ヒートマップ要素が存在する
        end
      end

      context '相互フォローのみの場合' do
        before { profile_owner.update(post_visibility: :mutual_followers) }

        context '相互フォロー関係がない場合' do
          it '非公開メッセージが表示される' do
            get user_profile_path(profile_owner.account_id)
            expect(response).to have_http_status(:success)
            expect(response.body).to include('このユーザーは投稿を非公開にしています')
            expect(response.body).to include('相互フォロー関係を結ぶと、投稿が閲覧できるようになります')
            expect(response.body).not_to include(post1.contentable.content)
          end
        end

        context '相互フォロー関係がある場合' do
          before do
            viewer.follow(profile_owner)
            profile_owner.follow(viewer)
          end

          it '投稿とヒートマップが表示される' do
            get user_profile_path(profile_owner.account_id)
            expect(response).to have_http_status(:success)
            expect(response.body).to include(post1.contentable.content)
            expect(response.body).to include(post2.contentable.content)
          end
        end
      end

      context '自分だけの場合' do
        before { profile_owner.update(post_visibility: :only_me) }

        it '非公開メッセージが表示される' do
          get user_profile_path(profile_owner.account_id)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('このユーザーは投稿を非公開にしています')
          expect(response.body).to include('投稿は本人のみ閲覧可能です')
          expect(response.body).not_to include(post1.contentable.content)
        end
      end

      context '本人の場合' do
        before do
          sign_in profile_owner
          profile_owner.update(post_visibility: :only_me)
        end

        it '投稿とヒートマップが表示される' do
          get user_profile_path(profile_owner.account_id)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(post1.contentable.content)
          expect(response.body).to include(post2.contentable.content)
        end
      end
    end

    describe "GET /users/:id/following (フォローリストの表示制御)" do
      let!(:viewer) { create(:user) }
      let!(:profile_owner) { create(:user, post_visibility: :everyone) }
      let!(:followed_user) { create(:user) }

      before do
        profile_owner.follow(followed_user)
        sign_in viewer
      end

      context '全体公開の場合' do
        it 'フォローリストが表示される' do
          get following_user_path(profile_owner.account_id)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(followed_user.name)
        end
      end

      context '相互フォローのみの場合' do
        before { profile_owner.update(post_visibility: :mutual_followers) }

        context '相互フォロー関係がない場合' do
          it '非公開メッセージが表示される' do
            get following_user_path(profile_owner.account_id)
            expect(response).to have_http_status(:success)
            expect(response.body).to include('このユーザーはフォローリストを非公開にしています')
            expect(response.body).not_to include(followed_user.name)
          end
        end

        context '相互フォロー関係がある場合' do
          before do
            viewer.follow(profile_owner)
            profile_owner.follow(viewer)
          end

          it 'フォローリストが表示される' do
            get following_user_path(profile_owner.account_id)
            expect(response).to have_http_status(:success)
            expect(response.body).to include(followed_user.name)
          end
        end
      end

      context '自分だけの場合' do
        before { profile_owner.update(post_visibility: :only_me) }

        it '非公開メッセージが表示される' do
          get following_user_path(profile_owner.account_id)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('このユーザーはフォローリストを非公開にしています')
          expect(response.body).not_to include(followed_user.name)
        end
      end
    end

    describe "GET /users/:id/followers (フォロワーリストの表示制御)" do
      let!(:viewer) { create(:user) }
      let!(:profile_owner) { create(:user, post_visibility: :everyone) }
      let!(:follower_user) { create(:user) }

      before do
        follower_user.follow(profile_owner)
        sign_in viewer
      end

      context '全体公開の場合' do
        it 'フォロワーリストが表示される' do
          get followers_user_path(profile_owner.account_id)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(follower_user.name)
        end
      end

      context '相互フォローのみの場合' do
        before { profile_owner.update(post_visibility: :mutual_followers) }

        context '相互フォロー関係がない場合' do
          it '非公開メッセージが表示される' do
            get followers_user_path(profile_owner.account_id)
            expect(response).to have_http_status(:success)
            expect(response.body).to include('このユーザーはフォローリストを非公開にしています')
            expect(response.body).not_to include(follower_user.name)
          end
        end

        context '相互フォロー関係がある場合' do
          before do
            viewer.follow(profile_owner)
            profile_owner.follow(viewer)
          end

          it 'フォロワーリストが表示される' do
            get followers_user_path(profile_owner.account_id)
            expect(response).to have_http_status(:success)
            expect(response.body).to include(follower_user.name)
          end
        end
      end
    end
  end
end
