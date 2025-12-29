require 'rails_helper'

RSpec.describe LlmUsage, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, admin: false) }
  let(:admin_user) { create(:user, admin: true) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      llm_usage = build(:llm_usage)
      expect(llm_usage).to be_valid
    end

    it 'requires usage_date' do
      llm_usage = build(:llm_usage, usage_date: nil)
      expect(llm_usage).not_to be_valid
    end

    it 'requires count' do
      llm_usage = build(:llm_usage, count: nil)
      expect(llm_usage).not_to be_valid
    end

    it 'requires count to be greater than or equal to 0' do
      llm_usage = build(:llm_usage, count: -1)
      expect(llm_usage).not_to be_valid
    end

    it 'requires unique usage_date per user' do
      create(:llm_usage, user: user, usage_date: Date.current)
      duplicate = build(:llm_usage, user: user, usage_date: Date.current)
      expect(duplicate).not_to be_valid
    end

    it 'allows same usage_date for different users' do
      create(:llm_usage, user: user, usage_date: Date.current)
      other_user_usage = build(:llm_usage, user: create(:user), usage_date: Date.current)
      expect(other_user_usage).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe '.find_or_create_today' do
    it '今日のレコードが存在しない場合、新規作成する' do
      expect {
        LlmUsage.find_or_create_today(user)
      }.to change(LlmUsage, :count).by(1)
    end

    it '今日のレコードが存在する場合、既存レコードを返す' do
      existing = create(:llm_usage, user: user, usage_date: Date.current, count: 5)
      result = LlmUsage.find_or_create_today(user)
      expect(result.id).to eq(existing.id)
      expect(result.count).to eq(5)
    end

    it '新規作成時にcountを0に初期化する' do
      result = LlmUsage.find_or_create_today(user)
      expect(result.count).to eq(0)
    end
  end

  describe '.check_and_reserve!' do
    context '一般ユーザー' do
      it '制限内の場合、カウントを1増やす' do
        usage = create(:llm_usage, user: user, usage_date: Date.current, count: 10)
        LlmUsage.check_and_reserve!(user)
        expect(usage.reload.count).to eq(11)
      end

      it '制限に達している場合、LimitExceededErrorを発生させる' do
        create(:llm_usage, user: user, usage_date: Date.current, count: 20)
        expect {
          LlmUsage.check_and_reserve!(user)
        }.to raise_error(LlmUsage::LimitExceededError)
      end

      it '制限に達している場合、カウントを増やさない' do
        usage = create(:llm_usage, user: user, usage_date: Date.current, count: 20)
        expect {
          LlmUsage.check_and_reserve!(user)
        }.to raise_error(LlmUsage::LimitExceededError)
        expect(usage.reload.count).to eq(20)
      end

      it '19回目の使用後、20回目が可能' do
        usage = create(:llm_usage, user: user, usage_date: Date.current, count: 19)
        expect {
          LlmUsage.check_and_reserve!(user)
        }.not_to raise_error
        expect(usage.reload.count).to eq(20)
      end

      it '20回目の使用後、21回目でエラー' do
        usage = create(:llm_usage, user: user, usage_date: Date.current, count: 20)
        expect {
          LlmUsage.check_and_reserve!(user)
        }.to raise_error(LlmUsage::LimitExceededError)
      end

      it '新規ユーザーの初回使用でレコードを作成し、カウントを1にする' do
        new_user = create(:user, admin: false)
        expect {
          LlmUsage.check_and_reserve!(new_user)
        }.to change(LlmUsage, :count).by(1)

        usage = LlmUsage.find_by(user: new_user, usage_date: Date.current)
        expect(usage.count).to eq(1)
      end
    end

    context '管理者ユーザー' do
      it '何もせず正常に終了する' do
        expect {
          LlmUsage.check_and_reserve!(admin_user)
        }.not_to change(LlmUsage, :count)
      end

      it 'LimitExceededErrorを発生させない' do
        expect {
          100.times { LlmUsage.check_and_reserve!(admin_user) }
        }.not_to raise_error
      end
    end

    context '並行実行' do
      it '複数スレッドからの同時アクセスでも正しくカウントする' do
        usage = create(:llm_usage, user: user, usage_date: Date.current, count: 0)

        threads = 5.times.map do
          Thread.new do
            begin
              LlmUsage.check_and_reserve!(user)
            rescue LlmUsage::LimitExceededError
              # 制限超過は許容
            end
          end
        end

        threads.each(&:join)
        expect(usage.reload.count).to eq(5)
      end

      it '制限ギリギリでの並行アクセスで制限を超えない' do
        usage = create(:llm_usage, user: user, usage_date: Date.current, count: 18)

        errors = []
        threads = 5.times.map do
          Thread.new do
            begin
              LlmUsage.check_and_reserve!(user)
            rescue LlmUsage::LimitExceededError => e
              errors << e
            end
          end
        end

        threads.each(&:join)

        # 18 + 2 = 20（制限）、残り3つはエラー
        expect(usage.reload.count).to eq(20)
        expect(errors.size).to eq(3)
      end
    end
  end

  describe '.remaining_count' do
    context '一般ユーザー' do
      it '使用回数0の場合、20を返す' do
        create(:llm_usage, user: user, usage_date: Date.current, count: 0)
        expect(LlmUsage.remaining_count(user)).to eq(20)
      end

      it '使用回数10の場合、10を返す' do
        create(:llm_usage, user: user, usage_date: Date.current, count: 10)
        expect(LlmUsage.remaining_count(user)).to eq(10)
      end

      it '使用回数20の場合、0を返す' do
        create(:llm_usage, user: user, usage_date: Date.current, count: 20)
        expect(LlmUsage.remaining_count(user)).to eq(0)
      end

      it 'レコードが存在しない場合、20を返す' do
        expect(LlmUsage.remaining_count(user)).to eq(20)
      end
    end

    context '管理者ユーザー' do
      it 'Float::INFINITYを返す' do
        expect(LlmUsage.remaining_count(admin_user)).to eq(Float::INFINITY)
      end
    end
  end

  describe '.stats' do
    context '一般ユーザー' do
      it '正しい統計情報を返す' do
        create(:llm_usage, user: user, usage_date: Date.current, count: 5)
        stats = LlmUsage.stats(user)

        expect(stats[:is_admin]).to eq(false)
        expect(stats[:daily_limit]).to eq(20)
        expect(stats[:today_count]).to eq(5)
        expect(stats[:remaining]).to eq(15)
      end

      it 'レコードが存在しない場合でも正しい統計情報を返す' do
        stats = LlmUsage.stats(user)

        expect(stats[:is_admin]).to eq(false)
        expect(stats[:daily_limit]).to eq(20)
        expect(stats[:today_count]).to eq(0)
        expect(stats[:remaining]).to eq(20)
      end
    end

    context '管理者ユーザー' do
      it '管理者用の統計情報を返す' do
        stats = LlmUsage.stats(admin_user)

        expect(stats[:is_admin]).to eq(true)
        expect(stats[:daily_limit]).to be_nil
        expect(stats[:today_count]).to be_nil
        expect(stats[:remaining]).to eq(Float::INFINITY)
      end
    end
  end

  describe '日付遷移のテスト' do
    it '日付が変わると新しいレコードが作成される' do
      travel_to Time.zone.parse('2025-01-01 23:59:00') do
        create(:llm_usage, user: user, usage_date: Date.current, count: 20)
      end

      travel_to Time.zone.parse('2025-01-02 00:01:00') do
        expect {
          LlmUsage.check_and_reserve!(user)
        }.to change(LlmUsage, :count).by(1)

        new_usage = LlmUsage.find_by(user: user, usage_date: Date.current)
        expect(new_usage.count).to eq(1)
        expect(new_usage.usage_date).to eq(Date.parse('2025-01-02'))
      end
    end

    it '真夜中をまたぐ原子性テスト' do
      usage = nil

      travel_to Time.zone.parse('2025-01-01 23:59:59') do
        usage = create(:llm_usage, user: user, usage_date: Date.current, count: 19)

        # 23:59:59に開始
        LlmUsage.check_and_reserve!(user)
      end

      # 日付が変わる前に予約されたので、1月1日のカウントが20になる
      expect(usage.reload.count).to eq(20)
      expect(usage.usage_date).to eq(Date.parse('2025-01-01'))
    end
  end
end
