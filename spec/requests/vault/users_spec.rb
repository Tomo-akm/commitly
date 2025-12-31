require 'rails_helper'

RSpec.describe "Vault::Users", type: :request do
  let(:current_user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in current_user
  end

  describe "GET /vault/users/:id" do
    context '他ユーザーのVaultを閲覧する場合' do
      it '公開ESのみ表示される' do
        public_es = create(:entry_sheet, user: other_user, visibility: :visibility_public, company_name: '公開株式会社')
        private_es = create(:entry_sheet, user: other_user, visibility: :visibility_private, company_name: '非公開株式会社')

        get vault_user_path(other_user)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('公開株式会社')
        expect(response.body).not_to include('非公開株式会社')
      end

      it '公開投稿から企業別進捗を集計する' do
        # 公開投稿を作成
        job_hunting_content = create(:job_hunting_content,
                                     company_name: 'テスト株式会社',
                                     selection_stage: 'first_interview',
                                     result: 'passed')
        create(:post, user: other_user, contentable: job_hunting_content, visibility: 'public')

        # 非公開投稿を作成
        private_content = create(:job_hunting_content,
                                company_name: '非公開企業',
                                selection_stage: 'final_interview',
                                result: 'pending')
        create(:post, user: other_user, contentable: private_content, visibility: 'private')

        get vault_user_path(other_user)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('テスト株式会社')
        expect(response.body).not_to include('非公開企業')
      end

      it 'ページネーションが機能する' do
        25.times { create(:entry_sheet, user: other_user, visibility: :visibility_public) }

        get vault_user_path(other_user), params: { page: 2 }

        expect(response).to have_http_status(:success)
      end
    end

    context 'ログインしていない場合' do
      before do
        sign_out current_user
      end

      it 'ログインページにリダイレクトされる' do
        get vault_user_path(other_user)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
