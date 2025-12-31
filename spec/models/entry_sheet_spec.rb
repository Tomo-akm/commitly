require 'rails_helper'

RSpec.describe EntrySheet, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:entry_sheet_items).dependent(:destroy) }
  end

  describe 'バリデーション' do
    it { is_expected.to validate_presence_of(:company_name) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'enum' do
    it do
      is_expected.to define_enum_for(:status).with_values(
        draft: 0,
        in_progress: 1,
        completed: 2,
        submitted: 3,
        passed: 4,
        failed: 5
      ).with_prefix(true)
    end

    it do
      is_expected.to define_enum_for(:visibility).with_values(
        visibility_private: 0,
        visibility_public: 1
      ).with_prefix(true)
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }

    describe '.publicly_visible' do
      it '公開設定のESのみを返す' do
        public_es = create(:entry_sheet, user: user, visibility: :visibility_public)
        private_es = create(:entry_sheet, user: user, visibility: :visibility_private)

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

        expect(described_class.recent.first).to eq(new_es)
        expect(described_class.recent.last).to eq(old_es)
      end
    end
  end

  describe 'デフォルト値' do
    it 'visibilityのデフォルトはprivate' do
      user = create(:user)
      entry_sheet = user.entry_sheets.create!(company_name: 'テスト株式会社')

      expect(entry_sheet.visibility_private?).to be true
    end
  end

  describe '#viewable_by?' do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:entry_sheet) { create(:entry_sheet, user: owner) }

    context 'ESの所有者の場合' do
      it 'trueを返す（公開範囲に関わらず）' do
        entry_sheet.update(visibility: :visibility_private)
        expect(entry_sheet.viewable_by?(owner)).to be true

        entry_sheet.update(visibility: :visibility_public)
        expect(entry_sheet.viewable_by?(owner)).to be true
      end
    end

    context '他のユーザーの場合' do
      it '公開ESならtrueを返す' do
        entry_sheet.update(visibility: :visibility_public)
        expect(entry_sheet.viewable_by?(other_user)).to be true
      end

      it '非公開ESならfalseを返す' do
        entry_sheet.update(visibility: :visibility_private)
        expect(entry_sheet.viewable_by?(other_user)).to be false
      end
    end
  end
end
