require 'rails_helper'

RSpec.describe EntrySheet, type: :model do
  describe 'アソシエーション' do
    it 'userに属する' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'entry_sheet_itemsを複数持つ' do
      expect(described_class.reflect_on_association(:entry_sheet_items).macro).to eq(:has_many)
    end
  end

  describe 'バリデーション' do
    it 'company_nameが必須' do
      entry_sheet = build(:entry_sheet, company_name: nil)
      expect(entry_sheet).not_to be_valid
      expect(entry_sheet.errors[:company_name]).to be_present
    end

    it 'statusが必須' do
      entry_sheet = build(:entry_sheet, status: nil)
      expect(entry_sheet).not_to be_valid
      expect(entry_sheet.errors[:status]).to be_present
    end

    it 'visibilityが必須' do
      entry_sheet = build(:entry_sheet, visibility: nil)
      expect(entry_sheet).not_to be_valid
      expect(entry_sheet.errors[:visibility]).to be_present
    end
  end

  describe 'enum' do
    it 'statusのenumが正しく定義されている' do
      entry_sheet = create(:entry_sheet)

      expect(entry_sheet).to respond_to(:status_draft?)
      expect(entry_sheet).to respond_to(:status_in_progress?)
      expect(entry_sheet).to respond_to(:status_completed?)
      expect(entry_sheet).to respond_to(:status_submitted?)
      expect(entry_sheet).to respond_to(:status_passed?)
      expect(entry_sheet).to respond_to(:status_failed?)
    end

    it 'visibilityのenumが正しく定義されている' do
      entry_sheet = create(:entry_sheet)

      expect(entry_sheet).to respond_to(:visibility_personal?)
      expect(entry_sheet).to respond_to(:visibility_shared?)
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }

    describe '.publicly_visible' do
      it '公開設定のESのみを返す' do
        public_es = create(:entry_sheet, user: user, visibility: :shared)
        private_es = create(:entry_sheet, user: user, visibility: :personal)

        expect(described_class.publicly_visible).to include(public_es)
        expect(described_class.publicly_visible).not_to include(private_es)
      end
    end

    describe '.upcoming_deadline' do
      it '2週間以内の締切のESを返す' do
        upcoming = create(:entry_sheet, user: user, deadline: 1.week.from_now)
        far_future = create(:entry_sheet, user: user, deadline: 3.weeks.from_now)
        no_deadline = create(:entry_sheet, user: user, deadline: nil)

        expect(described_class.upcoming_deadline).to include(upcoming)
        expect(described_class.upcoming_deadline).not_to include(far_future)
        expect(described_class.upcoming_deadline).not_to include(no_deadline)
      end
    end

    describe '.recent' do
      it '新しい順にESを返す' do
        old_es = create(:entry_sheet, user: user, created_at: 2.days.ago)
        new_es = create(:entry_sheet, user: user, created_at: 1.day.ago)

        recent_es = user.entry_sheets.recent
        expect(recent_es.first).to eq(new_es)
        expect(recent_es.last).to eq(old_es)
      end
    end
  end

  describe 'デフォルト値' do
    it 'visibilityのデフォルトはpersonal' do
      user = create(:user)
      entry_sheet = user.entry_sheets.create!(company_name: 'テスト株式会社')

      expect(entry_sheet.visibility_personal?).to be true
    end
  end

  describe '#viewable_by?' do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:entry_sheet) { create(:entry_sheet, user: owner) }

    context 'ESの所有者の場合' do
      it 'trueを返す（公開範囲に関わらず）' do
        entry_sheet.update(visibility: :personal)
        expect(entry_sheet.viewable_by?(owner)).to be true

        entry_sheet.update(visibility: :shared)
        expect(entry_sheet.viewable_by?(owner)).to be true
      end
    end

    context '他のユーザーの場合' do
      it '公開ESならtrueを返す' do
        entry_sheet.update(visibility: :shared)
        expect(entry_sheet.viewable_by?(other_user)).to be true
      end

      it '非公開ESならfalseを返す' do
        entry_sheet.update(visibility: :personal)
        expect(entry_sheet.viewable_by?(other_user)).to be false
      end
    end

    context 'ログアウトユーザー（userがnil）の場合' do
      it 'falseを返す（公開ESでも閲覧不可）' do
        entry_sheet.update(visibility: :shared)
        expect(entry_sheet.viewable_by?(nil)).to be false
      end

      it '非公開ESもfalseを返す' do
        entry_sheet.update(visibility: :personal)
        expect(entry_sheet.viewable_by?(nil)).to be false
      end
    end
  end
end
