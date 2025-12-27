require 'rails_helper'

RSpec.describe InternExperienceContent, type: :model do
  describe 'バリデーション' do
    it '有効な属性の場合、有効であること' do
      intern_experience_content = build(:intern_experience_content)
      expect(intern_experience_content).to be_valid
    end

    it 'company_nameが必須であること' do
      intern_experience_content = build(:intern_experience_content, company_name: nil)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:company_name]).to include("を入力してください")
    end

    it 'company_nameが100文字を超える場合、無効であること' do
      intern_experience_content = build(:intern_experience_content, company_name: 'a' * 101)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:company_name]).to include("は100文字以内で入力してください")
    end

    it 'contentが必須であること' do
      intern_experience_content = build(:intern_experience_content, content: nil)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:content]).to include("を入力してください")
    end

    it 'contentが5000文字を超える場合、無効であること' do
      intern_experience_content = build(:intern_experience_content, content: 'a' * 5001)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:content]).to include("は5000文字以内で入力してください")
    end

    it 'contentが5000文字以内の場合、有効であること' do
      intern_experience_content = build(:intern_experience_content, content: 'a' * 5000)
      expect(intern_experience_content).to be_valid
    end

    it 'event_nameが必須であること' do
      intern_experience_content = build(:intern_experience_content, event_name: nil)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:event_name]).to include("を入力してください")
    end

    it 'event_nameが100文字を超える場合、無効であること' do
      intern_experience_content = build(:intern_experience_content, event_name: 'a' * 101)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:event_name]).to include("は100文字以内で入力してください")
    end

    it 'duration_daysが空白でも有効であること' do
      intern_experience_content = build(:intern_experience_content, duration_days: nil)
      expect(intern_experience_content).to be_valid
    end

    it 'duration_daysが正の整数の場合、有効であること' do
      intern_experience_content = build(:intern_experience_content, duration_days: 14)
      expect(intern_experience_content).to be_valid
    end

    it 'duration_daysが0以下の場合、無効であること' do
      intern_experience_content = build(:intern_experience_content, duration_days: 0)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:duration_days]).to be_present
    end

    it 'duration_daysが整数でない場合、無効であること' do
      intern_experience_content = build(:intern_experience_content, duration_days: 1.5)
      expect(intern_experience_content).not_to be_valid
      expect(intern_experience_content.errors[:duration_days]).to be_present
    end
  end

  describe '関連' do
    it 'postと1対1の関連を持つこと' do
      association = described_class.reflect_on_association(:post)
      expect(association.macro).to eq(:has_one)
      expect(association.options[:as]).to eq(:contentable)
    end

    it '削除時に関連するpostも削除されること' do
      post = create(:post, :intern_experience)
      intern_experience_content = post.contentable

      expect { intern_experience_content.destroy }.to change(Post, :count).by(-1)
    end
  end

  describe '企業名の自動タグ化' do
    context '新規作成時' do
      it '企業名が自動的にタグとして追加される' do
        user = create(:user)
        intern_content = build(:intern_experience_content, company_name: "株式会社テスト")
        post = build(:post, user: user, contentable: intern_content)

        expect {
          post.save!
        }.to change { Tag.count }.by(1)

        expect(post.tags.count).to eq(1)
        expect(post.tags.first.name).to eq("テスト".downcase)
      end

      it '企業名から株式会社などの法人格が除去される' do
        user = create(:user)

        # 株式会社
        intern_content1 = build(:intern_experience_content, company_name: "株式会社サンプル")
        post1 = create(:post, user: user, contentable: intern_content1)
        expect(post1.tags.pluck(:name)).to include("サンプル".downcase)

        # 有限会社
        intern_content2 = build(:intern_experience_content, company_name: "有限会社テスト")
        post2 = create(:post, user: user, contentable: intern_content2)
        expect(post2.tags.pluck(:name)).to include("テスト".downcase)

        # 合同会社
        intern_content3 = build(:intern_experience_content, company_name: "合同会社デモ")
        post3 = create(:post, user: user, contentable: intern_content3)
        expect(post3.tags.pluck(:name)).to include("デモ".downcase)
      end

      it '(株)などの省略形も除去される' do
        user = create(:user)
        intern_content = build(:intern_experience_content, company_name: "(株)サンプル")
        post = create(:post, user: user, contentable: intern_content)

        expect(post.tags.pluck(:name)).to include("サンプル")
        expect(post.tags.pluck(:name)).not_to include("(株)サンプル")
      end
    end

    context '更新時' do
      it '企業名を更新してPostを保存するとタグも更新される' do
        user = create(:user)
        intern_content = create(:intern_experience_content, company_name: "株式会社テスト")
        post = create(:post, user: user, contentable: intern_content)

        expect(post.tags.first.name).to eq("テスト")

        # 企業名を更新してPostを保存（after_saveをトリガー）
        intern_content.update!(company_name: "株式会社別会社")
        post.save!

        expect(post.reload.tags.count).to eq(1)
        expect(post.tags.first.name).to eq("別会社")
      end
    end

    context '複数の投稿' do
      it '同じ企業名の投稿は同じタグを共有する' do
        user = create(:user)
        intern_content1 = build(:intern_experience_content, company_name: "株式会社テスト")
        post1 = create(:post, user: user, contentable: intern_content1)

        intern_content2 = build(:intern_experience_content, company_name: "テスト株式会社")
        post2 = create(:post, user: user, contentable: intern_content2)

        expect(post1.tags.pluck(:name)).to match_array(post2.tags.pluck(:name))
        expect(Tag.where(name: "テスト").count).to eq(1)
      end
    end

    context 'タグ作成失敗時' do
      it '投稿もロールバックされる' do
        user = create(:user)
        intern_content = build(:intern_experience_content, company_name: "株式会社テスト")
        post = build(:post, user: user, contentable: intern_content)

        # タグ作成で例外が出た場合にロールバックされることを確認
        allow(Tag).to receive(:find_or_create_by_names).and_raise(ActiveRecord::RecordInvalid.new(Tag.new))

        expect {
          post.save!
        }.to raise_error(ActiveRecord::RecordInvalid)

        # 投稿もロールバックされていることを確認
        expect(Post.where(user: user).count).to eq(0)
        expect(InternExperienceContent.where(company_name: "株式会社テスト").count).to eq(0)
      end
    end
  end

  describe 'プレゼンテーション用メソッド' do
    let(:intern_experience_content) { build(:intern_experience_content) }

    it 'type_nameで投稿タイプ名を返すこと' do
      expect(intern_experience_content.type_name).to eq("intern_experience")
    end

    it 'titleでインターン体験記用のタイトルを返すこと' do
      expect(intern_experience_content.title).to eq("インターン体験記 commit")
    end

    it 'success_messageでインターン体験記用の成功メッセージを返すこと' do
      expect(intern_experience_content.success_message).to eq("インターン体験記をpushしました")
    end
  end

  describe 'formatted_duration' do
    it 'duration_daysがnilの場合、nilを返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: nil)
      expect(intern_experience_content.formatted_duration).to be_nil
    end

    it '1日の場合、"1日"を返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 1)
      expect(intern_experience_content.formatted_duration).to eq("1日")
    end

    it '3日間の場合、"3日間"を返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 3)
      expect(intern_experience_content.formatted_duration).to eq("3日間")
    end

    it '1週間（7日）の場合、"1週間"を返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 7)
      expect(intern_experience_content.formatted_duration).to eq("1週間")
    end

    it '2週間（14日）の場合、"2週間"を返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 14)
      expect(intern_experience_content.formatted_duration).to eq("2週間")
    end

    it '1ヶ月（30日）の場合、"1ヶ月"を返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 30)
      expect(intern_experience_content.formatted_duration).to eq("1ヶ月")
    end

    it '3ヶ月（90日）の場合、"3ヶ月"を返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 90)
      expect(intern_experience_content.formatted_duration).to eq("3ヶ月")
    end

    it '6ヶ月（180日）の場合、"6ヶ月以上"を返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 180)
      expect(intern_experience_content.formatted_duration).to eq("6ヶ月以上")
    end

    it 'プリセット以外の日数の場合、nilを返すこと' do
      intern_experience_content = build(:intern_experience_content, duration_days: 21)
      expect(intern_experience_content.formatted_duration).to be_nil
    end
  end

  describe 'duration_presets_for_select' do
    it 'セレクトボックス用の選択肢配列を返すこと' do
      options = InternExperienceContent.duration_presets_for_select
      expect(options).to be_a(Array)
      expect(options.size).to eq(7)
      expect(options.first).to eq([ "1日", 1 ])
      expect(options.last).to eq([ "6ヶ月", 180 ])
    end
  end
end
