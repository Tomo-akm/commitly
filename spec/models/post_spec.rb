require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      post = build(:post)
      expect(post).to be_valid
    end

    it 'requires content' do
      general_content = build(:general_content, content: nil)
      post = build(:post, contentable: general_content)
      expect(post).not_to be_valid
    end

    it 'requires a user' do
      post = build(:post, user: nil)
      expect(post).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'has many tags through post_tags' do
      association = described_class.reflect_on_association(:tags)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:post_tags)
    end
  end

  describe '#tags' do
    it 'can have multiple tags' do
      post = create(:post)
      tag1 = create(:tag)
      tag2 = create(:tag)

      post.tags << [ tag1, tag2 ]

      expect(post.tags).to include(tag1, tag2)
      expect(post.tags.count).to eq(2)
    end
  end

  describe 'CONTENTABLE_TYPES' do
    it 'general と job_hunting のマッピングが定義されている' do
      expect(Post::CONTENTABLE_TYPES).to eq({
        'general' => GeneralContent,
        'job_hunting' => JobHuntingContent
      })
    end
  end

  describe '.build_with_type' do
    let(:user) { create(:user) }

    context 'type が general の場合' do
      it 'GeneralContent を持つ Post を返す' do
        post = user.posts.build_with_type('general')
        expect(post).to be_a(Post)
        expect(post.contentable).to be_a(GeneralContent)
        expect(post.contentable).to be_new_record
      end
    end

    context 'type が job_hunting の場合' do
      it 'JobHuntingContent を持つ Post を返す' do
        post = user.posts.build_with_type('job_hunting')
        expect(post).to be_a(Post)
        expect(post.contentable).to be_a(JobHuntingContent)
        expect(post.contentable).to be_new_record
      end
    end

    context 'type が nil またはデフォルトの場合' do
      it 'GeneralContent を持つ Post を返す' do
        post = user.posts.build_with_type(nil)
        expect(post.contentable).to be_a(GeneralContent)
      end

      it 'type を省略した場合も GeneralContent を持つ' do
        post = user.posts.build_with_type
        expect(post.contentable).to be_a(GeneralContent)
      end
    end

    context '不明な type が渡された場合' do
      it 'ArgumentError を発生させる' do
        expect {
          user.posts.build_with_type('unknown_type')
        }.to raise_error(ArgumentError, /不明な投稿タイプ/)
      end
    end
  end

  describe '#build_contentable' do
    let(:post) { Post.new }

    context 'general を指定した場合' do
      it 'GeneralContent を build する' do
        post.build_contentable('general')
        expect(post.contentable).to be_a(GeneralContent)
        expect(post.contentable).to be_new_record
      end
    end

    context 'job_hunting を指定した場合' do
      it 'JobHuntingContent を build する' do
        post.build_contentable('job_hunting')
        expect(post.contentable).to be_a(JobHuntingContent)
        expect(post.contentable).to be_new_record
      end
    end

    context '不明な type が渡された場合' do
      it 'ArgumentError を発生させる' do
        expect {
          post.build_contentable('unknown_type')
        }.to raise_error(ArgumentError, /不明な投稿タイプ/)
      end
    end
  end

  describe '#update_with_form_params' do
    let(:user) { create(:user) }

    context '通常投稿の場合' do
      let(:post) { user.posts.build_with_type('general') }

      it 'contentableのパラメータを更新できる' do
        result = post.update_with_form_params({ content: 'テスト投稿' })
        expect(result).to be true
        expect(post.reload.contentable.content).to eq('テスト投稿')
      end

      it 'タグを設定できる' do
        result = post.update_with_form_params(
          { content: 'テスト投稿' },
          { tag_names: 'Ruby, Rails' }
        )
        expect(result).to be true
        expect(post.reload.tags.pluck(:name)).to contain_exactly('ruby', 'rails')
      end

      it 'タグが空の場合は設定されない' do
        result = post.update_with_form_params(
          { content: 'テスト投稿' },
          { tag_names: '' }
        )
        expect(result).to be true
        expect(post.reload.tags).to be_empty
      end
    end

    context '就活投稿の場合' do
      let(:post) { user.posts.build_with_type('job_hunting') }

      it 'contentableのパラメータを更新できる' do
        result = post.update_with_form_params({
          company_name: '株式会社テスト',
          selection_stage: 'es',
          result: 'pending',
          content: 'ES提出しました'
        })
        expect(result).to be true
        expect(post.reload.contentable.company_name).to eq('株式会社テスト')
        expect(post.reload.contentable.selection_stage).to eq('es')
      end

      it 'タグを渡しても無視される（企業名タグのみ設定される）' do
        result = post.update_with_form_params(
          {
            company_name: '株式会社テスト',
            selection_stage: 'es',
            result: 'pending',
            content: 'ES提出しました'
          },
          { tag_names: 'Ruby, Rails' }
        )
        expect(result).to be true
        # 企業名タグのみが設定される
        expect(post.reload.tags.pluck(:name)).to contain_exactly('テスト'.downcase)
      end
    end

    context 'バリデーションエラーの場合' do
      let(:post) { user.posts.build_with_type('general') }

      it 'falseを返す' do
        result = post.update_with_form_params({ content: '' })
        expect(result).to be false
        expect(post.errors).to be_present
      end
    end
  end
end
