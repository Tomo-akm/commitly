require 'rails_helper'

RSpec.describe JobHuntingContent, type: :model do
  describe 'バリデーション' do
    it '有効な属性の場合、有効であること' do
      job_hunting_content = build(:job_hunting_content)
      expect(job_hunting_content).to be_valid
    end

    it 'company_nameが必須であること' do
      job_hunting_content = build(:job_hunting_content, company_name: nil)
      expect(job_hunting_content).not_to be_valid
      expect(job_hunting_content.errors[:company_name]).to include("を入力してください")
    end

    it 'company_nameが100文字を超える場合、無効であること' do
      job_hunting_content = build(:job_hunting_content, company_name: 'a' * 101)
      expect(job_hunting_content).not_to be_valid
      expect(job_hunting_content.errors[:company_name]).to include("は100文字以内で入力してください")
    end

    it 'selection_stageが必須であること' do
      job_hunting_content = build(:job_hunting_content, selection_stage: nil)
      expect(job_hunting_content).not_to be_valid
    end

    it 'resultが必須であること' do
      job_hunting_content = build(:job_hunting_content, result: nil)
      expect(job_hunting_content).not_to be_valid
    end

    it 'contentが必須であること' do
      job_hunting_content = build(:job_hunting_content, content: nil)
      expect(job_hunting_content).not_to be_valid
      expect(job_hunting_content.errors[:content]).to include("を入力してください")
    end

    it 'contentが5000文字を超える場合、無効であること' do
      job_hunting_content = build(:job_hunting_content, content: 'a' * 5001)
      expect(job_hunting_content).not_to be_valid
      expect(job_hunting_content.errors[:content]).to include("は5000文字以内で入力してください")
    end
  end

  describe 'enum' do
    it 'selection_stage enumが定義されていること' do
      expect(JobHuntingContent.selection_stages).to include(
        'es' => 0,
        'first_interview' => 1,
        'second_interview' => 2,
        'final_interview' => 3,
        'other' => 4
      )
    end

    it 'result enumが定義されていること' do
      expect(JobHuntingContent.results).to include(
        'passed' => 0,
        'failed' => 1,
        'pending' => 2
      )
    end

    it 'selection_stageを設定できること' do
      job_hunting_content = create(:job_hunting_content, selection_stage: :first_interview)
      expect(job_hunting_content.selection_stage_first_interview?).to be true
    end

    it 'resultを設定できること' do
      job_hunting_content = create(:job_hunting_content, result: :passed)
      expect(job_hunting_content.result_passed?).to be true
    end
  end

  describe '関連' do
    it 'postと1対1の関連を持つこと' do
      association = described_class.reflect_on_association(:post)
      expect(association.macro).to eq(:has_one)
      expect(association.options[:as]).to eq(:contentable)
    end

    it '削除時に関連するpostも削除されること' do
      post = create(:post, :job_hunting)
      job_hunting_content = post.contentable

      expect { job_hunting_content.destroy }.to change(Post, :count).by(-1)
    end
  end

  describe '日本語化メソッド' do
    it 'selection_stage_jaで日本語の選考段階を返すこと' do
      job_hunting_content = create(:job_hunting_content, selection_stage: :es)
      expect(job_hunting_content.selection_stage_ja).to eq("ES")
    end

    it 'result_jaで日本語の結果を返すこと' do
      job_hunting_content = create(:job_hunting_content, result: :passed)
      expect(job_hunting_content.result_ja).to eq("通過")
    end
  end

  describe 'セレクトボックス用のオプション' do
    it 'selection_stages_for_selectで選択肢を返すこと' do
      options = JobHuntingContent.selection_stages_for_select
      expect(options).to be_an(Array)
      expect(options.first).to eq([ "ES", "es" ])
    end

    it 'results_for_selectで選択肢を返すこと' do
      options = JobHuntingContent.results_for_select
      expect(options).to be_an(Array)
      expect(options.first).to eq([ "通過", "passed" ])
    end
  end

  describe '企業名の自動タグ化' do
    context '新規作成時' do
      it '企業名が自動的にタグとして追加される' do
        user = create(:user)
        job_content = build(:job_hunting_content, company_name: "株式会社テスト")
        post = build(:post, user: user, contentable: job_content)

        expect {
          post.save!
        }.to change { Tag.count }.by(1)

        expect(post.tags.count).to eq(1)
        expect(post.tags.first.name).to eq("テスト".downcase)
      end

      it '企業名から株式会社などの法人格が除去される' do
        user = create(:user)

        # 株式会社
        job_content1 = build(:job_hunting_content, company_name: "株式会社サンプル")
        post1 = create(:post, user: user, contentable: job_content1)
        expect(post1.tags.pluck(:name)).to include("サンプル".downcase)

        # 有限会社
        job_content2 = build(:job_hunting_content, company_name: "有限会社テスト")
        post2 = create(:post, user: user, contentable: job_content2)
        expect(post2.tags.pluck(:name)).to include("テスト".downcase)

        # 合同会社
        job_content3 = build(:job_hunting_content, company_name: "合同会社デモ")
        post3 = create(:post, user: user, contentable: job_content3)
        expect(post3.tags.pluck(:name)).to include("デモ".downcase)
      end

      it '(株)などの省略形も除去される' do
        user = create(:user)
        job_content = build(:job_hunting_content, company_name: "(株)サンプル")
        post = create(:post, user: user, contentable: job_content)

        expect(post.tags.pluck(:name)).to include("サンプル".downcase)
        expect(post.tags.pluck(:name)).not_to include("(株)サンプル".downcase)
      end
    end

    context '更新時' do
      it '企業名を更新してPostを保存するとタグも更新される' do
        user = create(:user)
        job_content = create(:job_hunting_content, company_name: "株式会社テスト")
        post = create(:post, user: user, contentable: job_content)

        expect(post.tags.first.name).to eq("テスト".downcase)

        # 企業名を更新してPostを保存（after_saveをトリガー）
        job_content.update!(company_name: "株式会社別会社")
        post.save!

        expect(post.reload.tags.count).to eq(1)
        expect(post.tags.first.name).to eq("別会社".downcase)
      end
    end

    context '複数の投稿' do
      it '同じ企業名の投稿は同じタグを共有する' do
        user = create(:user)
        job_content1 = build(:job_hunting_content, company_name: "株式会社テスト")
        post1 = create(:post, user: user, contentable: job_content1)

        job_content2 = build(:job_hunting_content, company_name: "テスト株式会社")
        post2 = create(:post, user: user, contentable: job_content2)

        expect(post1.tags.pluck(:name)).to match_array(post2.tags.pluck(:name))
        expect(Tag.where(name: "テスト".downcase).count).to eq(1)
      end
    end

    context 'タグ作成失敗時' do
      it '投稿もロールバックされる' do
        user = create(:user)
        job_content = build(:job_hunting_content, company_name: "株式会社テスト")
        post = build(:post, user: user, contentable: job_content)

        # Tag.find_or_create_by!が例外を投げるようにモック
        allow(Tag).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid.new(Tag.new))

        expect {
          post.save!
        }.to raise_error(ActiveRecord::RecordInvalid)

        # 投稿もロールバックされていることを確認
        expect(Post.where(user: user).count).to eq(0)
        expect(JobHuntingContent.where(company_name: "株式会社テスト").count).to eq(0)
      end
    end
  end
end
