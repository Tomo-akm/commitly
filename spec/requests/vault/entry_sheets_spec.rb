require 'rails_helper'

RSpec.describe "Vault::EntrySheets", type: :request do
  let(:current_user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in current_user
  end

  describe "GET /vault/entry_sheets/:id" do
    context '自分のESを閲覧する場合' do
      it '公開範囲に関わらず閲覧できる' do
        private_es = create(:entry_sheet, user: current_user, visibility: :visibility_private)

        get vault_entry_sheet_path(private_es)

        expect(response).to have_http_status(:success)
      end
    end

    context '他ユーザーの公開ESを閲覧する場合' do
      it '閲覧できる' do
        public_es = create(:entry_sheet, user: other_user, visibility: :visibility_public)

        get vault_entry_sheet_path(public_es)

        expect(response).to have_http_status(:success)
      end
    end

    context '他ユーザーの非公開ESを閲覧しようとする場合' do
      it 'リダイレクトされる' do
        private_es = create(:entry_sheet, user: other_user, visibility: :visibility_private)

        get vault_entry_sheet_path(private_es)

        expect(response).to redirect_to(vault_root_path)
        expect(flash[:alert]).to eq('このESは公開されていません')
      end
    end
  end

  describe "POST /vault/entry_sheets" do
    let(:valid_params) do
      {
        entry_sheet: {
          company_name: 'テスト株式会社',
          status: 'draft',
          visibility: 'visibility_private',
          entry_sheet_items_attributes: {
            '0' => { title: '自己PR', content: 'テスト内容', char_limit: 400, position: 0 }
          }
        }
      }
    end

    it 'ESを作成できる' do
      expect {
        post vault_entry_sheets_path, params: valid_params
      }.to change(EntrySheet, :count).by(1)

      expect(response).to redirect_to(vault_entry_sheet_path(EntrySheet.last))
      expect(flash[:notice]).to eq('ESを作成しました')
    end

    it 'visibilityを設定できる' do
      post vault_entry_sheets_path, params: valid_params

      expect(EntrySheet.last.visibility_private?).to be true
    end
  end

  describe "PATCH /vault/entry_sheets/:id" do
    let(:entry_sheet) { create(:entry_sheet, user: current_user, visibility: :visibility_private) }

    it 'visibilityを更新できる' do
      patch vault_entry_sheet_path(entry_sheet), params: {
        entry_sheet: { visibility: 'visibility_public' }
      }

      expect(entry_sheet.reload.visibility_public?).to be true
      expect(response).to redirect_to(vault_entry_sheet_path(entry_sheet))
    end
  end
end
