require 'rails_helper'

RSpec.describe "Settings::Privacy", type: :request do
  let(:user) { create(:user, post_visibility: :everyone) }

  before do
    sign_in user
  end

  describe "GET /settings/privacy" do
    it "プライバシー設定ページが表示される" do
      get settings_privacy_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('プライバシー設定')
    end

    it "現在の設定が反映されている" do
      user.update(post_visibility: :mutual_followers)
      get settings_privacy_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('現在の設定')
    end

    it "全ての公開範囲選択肢が表示される" do
      get settings_privacy_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('全体公開')
      expect(response.body).to include('相互フォローのみ')
      expect(response.body).to include('自分だけ')
    end
  end

  describe "PATCH /settings/privacy" do
    context "有効なパラメータの場合" do
      it "公開範囲を everyone に更新できる" do
        user.update(post_visibility: :only_me)

        patch settings_privacy_path, params: {
          user: { post_visibility: 'everyone' }
        }

        expect(user.reload.post_visibility).to eq('everyone')
        expect(response).to redirect_to(settings_privacy_path)
      end

      it "公開範囲を mutual_followers に更新できる" do
        patch settings_privacy_path, params: {
          user: { post_visibility: 'mutual_followers' }
        }

        expect(user.reload.post_visibility).to eq('mutual_followers')
        expect(response).to redirect_to(settings_privacy_path)
      end

      it "公開範囲を only_me に更新できる" do
        patch settings_privacy_path, params: {
          user: { post_visibility: 'only_me' }
        }

        expect(user.reload.post_visibility).to eq('only_me')
        expect(response).to redirect_to(settings_privacy_path)
      end

      it "成功メッセージが表示される" do
        patch settings_privacy_path, params: {
          user: { post_visibility: 'mutual_followers' }
        }

        follow_redirect!
        expect(response.body).to include('プライバシー設定を更新しました')
      end
    end

    context "既存投稿への影響" do
      let!(:post1) { create(:post, user: user) }
      let!(:post2) { create(:post, user: user) }

      it "公開範囲を変更すると既存投稿も全て影響を受ける" do
        user.update(post_visibility: :everyone)
        viewer = create(:user)

        # 全体公開なので見える
        expect(post1.visible_to?(viewer)).to be true
        expect(post2.visible_to?(viewer)).to be true

        # 自分だけに変更
        patch settings_privacy_path, params: {
          user: { post_visibility: 'only_me' }
        }

        user.reload
        # 既存投稿も見えなくなる
        expect(post1.visible_to?(viewer)).to be false
        expect(post2.visible_to?(viewer)).to be false
      end
    end

    context "未ログイン" do
      it "ログインページにリダイレクトされる" do
        sign_out user
        patch settings_privacy_path, params: {
          user: { post_visibility: 'mutual_followers' }
        }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end