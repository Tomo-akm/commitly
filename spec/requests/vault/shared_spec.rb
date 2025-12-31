require 'rails_helper'

RSpec.describe "Vault::Shared", type: :request do
  let(:current_user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in current_user, scope: :user
  end

  describe "GET /vault/:account_id" do
    context '自分のVaultを閲覧する場合' do
      it '正常に表示される（ダッシュボードとは別ルート）' do
        create(:entry_sheet, user: current_user, visibility: :shared, company_name: '公開株式会社')

        get vault_path(current_user.account_id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('公開株式会社')
        expect(response.body).to include("#{current_user.name}のVault")
      end
    end

    context '他ユーザーの公開Vaultを閲覧する場合' do
      it '公開ESのみ表示される' do
        public_es = create(:entry_sheet, user: other_user, visibility: :shared, company_name: '公開株式会社')
        private_es = create(:entry_sheet, user: other_user, visibility: :personal, company_name: '非公開株式会社')

        get vault_path(other_user.account_id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('公開株式会社')
        expect(response.body).not_to include('非公開株式会社')
      end

      it '公開投稿から企業別進捗を集計する' do
        # other_userを公開設定に変更
        other_user.update!(post_visibility: :everyone)

        # 公開投稿を作成
        job_hunting_content = create(:job_hunting_content,
                                     company_name: 'テスト株式会社',
                                     selection_stage: 'first_interview',
                                     result: 'passed')
        create(:post, user: other_user, contentable: job_hunting_content)

        get vault_path(other_user.account_id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('テスト株式会社')
      end

      it 'ページネーションが機能する' do
        25.times { create(:entry_sheet, user: other_user, visibility: :shared) }

        get vault_path(other_user.account_id), params: { page: 2 }

        expect(response).to have_http_status(:success)
      end
    end

    context 'post_visibilityがonly_meの場合' do
      before do
        other_user.update!(post_visibility: :only_me)
        create(:entry_sheet, user: other_user, visibility: :shared, company_name: '公開株式会社')
      end

      it 'Vaultにアクセスできずリダイレクトされる' do
        get vault_path(other_user.account_id)

        expect(response).to redirect_to(vault_root_path)
        expect(flash[:alert]).to eq('このVaultは公開されていません')
      end
    end

    context 'post_visibilityがmutual_followersの場合' do
      before do
        other_user.update!(post_visibility: :mutual_followers)
        create(:entry_sheet, user: other_user, visibility: :shared, company_name: '公開株式会社')
      end

      context 'フォロー関係がない場合' do
        it 'Vaultにアクセスできずリダイレクトされる' do
          get vault_path(other_user.account_id)

          expect(response).to redirect_to(vault_root_path)
          expect(flash[:alert]).to eq('このVaultは公開されていません')
        end
      end

      context '片方向フォローの場合' do
        before do
          current_user.follow(other_user)
        end

        it 'Vaultにアクセスできずリダイレクトされる' do
          get vault_path(other_user.account_id)

          expect(response).to redirect_to(vault_root_path)
          expect(flash[:alert]).to eq('このVaultは公開されていません')
        end
      end

      context '相互フォローの場合' do
        before do
          current_user.follow(other_user)
          other_user.follow(current_user)
        end

        it 'Vaultにアクセスできる' do
          get vault_path(other_user.account_id)

          expect(response).to have_http_status(:success)
          expect(response.body).to include('公開株式会社')
        end
      end
    end

    context 'ログインしていない場合' do
      before do
        sign_out current_user
      end

      it 'ログインページにリダイレクトされる' do
        get vault_path(other_user.account_id)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ユーザーが存在しない場合' do
      it 'Vaultルートにリダイレクトされる' do
        get vault_path('nonexistent_user')

        expect(response).to redirect_to(vault_root_path)
        expect(flash[:alert]).to eq('ユーザーが見つかりません')
      end
    end

    context 'account_idが予約語の場合' do
      it 'entry_sheetsは名前空間ルートにルーティングされる（ユーザーVaultではない）' do
        # このテストはルーティングの競合を確認する
        # vault/entry_sheetsは vault_entry_sheets_path にマッチし、
        # vault_path("entry_sheets") にはマッチしない
        get '/vault/entry_sheets'

        # EntrySheets#indexにルーティングされる
        expect(response).to have_http_status(:success)
        # Shared#showではなくEntrySheets#indexであることを確認
        # （Shared#showの場合は「のVault」というテキストが含まれる）
        expect(response.body).not_to include('のVault')
      end
    end
  end
end
