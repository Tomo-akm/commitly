require 'rails_helper'

RSpec.describe "Vault::EntrySheets", type: :request do
  let(:current_user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in current_user, scope: :user
  end

  describe "GET /vault/entry_sheets/:id" do
    context '自分のESを閲覧する場合' do
      it '公開範囲に関わらず閲覧できる' do
        private_es = create(:entry_sheet, user: current_user, visibility: :personal)

        get vault_entry_sheet_path(private_es)

        expect(response).to have_http_status(:success)
      end
    end

    context '他ユーザーの公開ESを閲覧する場合' do
      it '閲覧できる' do
        public_es = create(:entry_sheet, user: other_user, visibility: :shared)

        get vault_entry_sheet_path(public_es)

        expect(response).to have_http_status(:success)
      end
    end

    context '他ユーザーの非公開ESを閲覧しようとする場合' do
      it 'リダイレクトされる' do
        private_es = create(:entry_sheet, user: other_user, visibility: :personal)

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
          visibility: 'personal',
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
      expect(flash[:notice]).to eq('ESを作成しました。つぶやきで共有してレビューをもらおう！')
    end

    it 'visibilityを設定できる' do
      post vault_entry_sheets_path, params: valid_params

      expect(EntrySheet.last.visibility_personal?).to be true
    end
  end

  describe "GET /vault/entry_sheets/:id/edit" do
    context '自分のESの場合' do
      it '編集ページが表示される' do
        my_es = create(:entry_sheet, user: current_user)
        my_es.entry_sheet_items.create!(title: 'テスト項目', content: 'テスト内容', position: 0)
        get edit_vault_entry_sheet_path(my_es)

        expect(response).to have_http_status(:success)
      end
    end

    context '他ユーザーのESの場合' do
      it 'リダイレクトされる' do
        other_es = create(:entry_sheet, user: other_user, visibility: :shared)
        get edit_vault_entry_sheet_path(other_es)

        expect(response).to redirect_to(vault_root_path)
        expect(flash[:alert]).to eq('他のユーザーのESは編集できません')
      end
    end
  end

  describe "PATCH /vault/entry_sheets/:id" do
    let(:entry_sheet) { create(:entry_sheet, user: current_user, visibility: :personal) }

    context '自分のESの場合' do
      it 'visibilityを更新できる' do
        patch vault_entry_sheet_path(entry_sheet), params: {
          entry_sheet: { visibility: 'shared' }
        }

        expect(entry_sheet.reload.visibility_shared?).to be true
        expect(response).to redirect_to(vault_entry_sheet_path(entry_sheet))
      end
    end

    context '他ユーザーのESの場合' do
      it '更新できずリダイレクトされる' do
        other_es = create(:entry_sheet, user: other_user, visibility: :shared, company_name: '元の企業名')

        patch vault_entry_sheet_path(other_es), params: {
          entry_sheet: { company_name: '改ざんされた企業名' }
        }

        expect(response).to redirect_to(vault_root_path)
        expect(flash[:alert]).to eq('他のユーザーのESは編集できません')
        expect(other_es.reload.company_name).to eq('元の企業名')
      end
    end
  end

  describe "DELETE /vault/entry_sheets/:id" do
    context '自分のESの場合' do
      it '削除できる' do
        my_es = create(:entry_sheet, user: current_user)

        expect {
          delete vault_entry_sheet_path(my_es)
        }.to change(EntrySheet, :count).by(-1)

        expect(response).to redirect_to(vault_entry_sheets_path)
      end
    end

    context '他ユーザーのESの場合' do
      it '削除できずリダイレクトされる' do
        other_es = create(:entry_sheet, user: other_user, visibility: :shared)

        expect {
          delete vault_entry_sheet_path(other_es)
        }.not_to change(EntrySheet, :count)

        expect(response).to redirect_to(vault_root_path)
        expect(flash[:alert]).to eq('他のユーザーのESは編集できません')
      end
    end
  end
end
