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

    it 'belongs to parent post (optional)' do
      association = described_class.reflect_on_association(:parent)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be true
    end

    it 'has many replies' do
      association = described_class.reflect_on_association(:replies)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:foreign_key]).to eq(:parent_id)
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

      it '本文中のハッシュタグをタグとして設定する' do
        result = post.update_with_form_params(
          { content: 'テスト投稿 #Ruby #Rails' }
        )
        expect(result).to be true
        expect(post.reload.tags.pluck(:name)).to contain_exactly('Ruby', 'Rails')
      end

      it 'ハッシュタグがない場合はタグがクリアされる' do
        post.update_with_form_params({ content: 'テスト投稿 #Ruby' })
        expect(post.tags.pluck(:name)).to contain_exactly('Ruby')

        result = post.update_with_form_params({ content: 'タグなしの投稿' })
        expect(result).to be true
        expect(post.reload.tags).to be_empty
      end

      it '大文字小文字を区別してタグを設定する' do
        result = post.update_with_form_params({ content: '#Ruby #ruby #RUBY' })
        expect(result).to be true
        expect(post.reload.tags.pluck(:name)).to contain_exactly('Ruby', 'ruby', 'RUBY')
      end

      it '全角スペースでもハッシュタグを認識する' do
        result = post.update_with_form_params({ content: 'テスト　#Ruby　#Rails' })
        expect(result).to be true
        expect(post.reload.tags.pluck(:name)).to contain_exactly('Ruby', 'Rails')
      end

      it '半角と全角スペースが混在していてもハッシュタグを認識する' do
        result = post.update_with_form_params({ content: 'テスト #Ruby　#Rails #JavaScript' })
        expect(result).to be true
        expect(post.reload.tags.pluck(:name)).to contain_exactly('Ruby', 'Rails', 'JavaScript')
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

      it '本文中のハッシュタグは無視され、企業名タグのみ設定される' do
        result = post.update_with_form_params(
          {
            company_name: '株式会社テスト',
            selection_stage: 'es',
            result: 'pending',
            content: 'ES提出しました #Ruby #Rails'
          }
        )
        expect(result).to be true
        # 企業名タグのみが設定される
        expect(post.reload.tags.pluck(:name)).to contain_exactly('テスト')
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

  describe 'リプライ機能' do
    let(:user) { create(:user) }
    let(:parent_post) { create(:post, user: user) }

    describe '親投稿への紐付け' do
      it '親投稿を持つリプライを作成できる' do
        reply = create(:post, user: user, parent: parent_post)

        expect(reply.parent).to eq(parent_post)
        expect(reply.parent_id).to eq(parent_post.id)
      end

      it '親投稿を持たない通常の投稿も作成できる' do
        post = create(:post, user: user, parent: nil)

        expect(post.parent).to be_nil
        expect(post.parent_id).to be_nil
      end
    end

    describe '親投稿からのリプライ取得' do
      it '親投稿から複数のリプライを取得できる' do
        reply1 = create(:post, user: user, parent: parent_post)
        reply2 = create(:post, user: user, parent: parent_post)
        reply3 = create(:post, user: user, parent: parent_post)

        expect(parent_post.replies).to contain_exactly(reply1, reply2, reply3)
        expect(parent_post.replies.count).to eq(3)
      end

      it 'リプライが存在しない場合は空の配列を返す' do
        expect(parent_post.replies).to be_empty
      end
    end

    describe 'ネストしたリプライ' do
      it 'リプライに対するリプライ（孫）も作成できる' do
        reply = create(:post, user: user, parent: parent_post)
        nested_reply = create(:post, user: user, parent: reply)

        expect(nested_reply.parent).to eq(reply)
        expect(reply.parent).to eq(parent_post)
        expect(reply.replies).to include(nested_reply)
      end
    end

    describe '親投稿削除時の動作' do
      it '親投稿が削除されるとリプライも削除される' do
        create(:post, user: user, parent: parent_post)
        create(:post, user: user, parent: parent_post)

        expect { parent_post.destroy }.to change(Post, :count).by(-3) # 親+リプライ2つ
      end
    end

    describe '#all_replies_count' do
      context 'リプライが存在しない場合' do
        it '0を返す' do
          expect(parent_post.all_replies_count).to eq(0)
        end
      end

      context '直下のリプライのみの場合' do
        it 'リプライ数を正しくカウントする' do
          create(:post, user: user, parent: parent_post)
          create(:post, user: user, parent: parent_post)
          create(:post, user: user, parent: parent_post)

          expect(parent_post.all_replies_count).to eq(3)
        end
      end

      context 'ネストしたリプライ（孫、ひ孫）も含む場合' do
        it '全ての子孫リプライをカウントする' do
          # 親投稿に3つのリプライ
          reply1 = create(:post, user: user, parent: parent_post)
          reply2 = create(:post, user: user, parent: parent_post)
          reply3 = create(:post, user: user, parent: parent_post)

          # reply1 に2つの孫リプライ
          nested_reply1 = create(:post, user: user, parent: reply1)
          nested_reply2 = create(:post, user: user, parent: reply1)

          # nested_reply1 にひ孫リプライ
          create(:post, user: user, parent: nested_reply1)

          # 合計: 3（直下） + 2（孫） + 1（ひ孫） = 6
          expect(parent_post.all_replies_count).to eq(6)
        end
      end

      context '複雑なネスト構造の場合' do
        it '全ての階層のリプライをカウントする' do
          # レベル1: 2つのリプライ
          reply1 = create(:post, user: user, parent: parent_post)
          reply2 = create(:post, user: user, parent: parent_post)

          # レベル2: reply1に2つ、reply2に1つ
          reply1_child1 = create(:post, user: user, parent: reply1)
          reply1_child2 = create(:post, user: user, parent: reply1)
          reply2_child1 = create(:post, user: user, parent: reply2)

          # レベル3: reply1_child1に1つ
          create(:post, user: user, parent: reply1_child1)

          # 合計: 2 + 3 + 1 = 6
          expect(parent_post.all_replies_count).to eq(6)
        end
      end
    end
  end

  describe '公開範囲機能' do
    let(:viewer) { create(:user) }
    let(:public_user) { create(:user, post_visibility: :everyone) }
    let(:mutual_user) { create(:user, post_visibility: :mutual_followers) }
    let(:private_user) { create(:user, post_visibility: :only_me) }

    let!(:public_post) { create(:post, user: public_user) }
    let!(:mutual_post) { create(:post, user: mutual_user) }
    let!(:private_post) { create(:post, user: private_user) }

    describe '.visible_to' do
      context 'viewer が nil の場合' do
        it '全体公開の投稿のみ返す' do
          posts = Post.visible_to(nil)
          expect(posts).to include(public_post)
          expect(posts).not_to include(mutual_post, private_post)
        end
      end

      context 'viewer が全体公開ユーザーの投稿を見る場合' do
        it '全体公開の投稿が見える' do
          posts = Post.visible_to(viewer)
          expect(posts).to include(public_post)
        end
      end

      context 'viewer が相互フォローユーザーの投稿を見る場合' do
        context '相互フォロー関係がない場合' do
          it '相互フォローのみの投稿は見えない' do
            posts = Post.visible_to(viewer)
            expect(posts).not_to include(mutual_post)
          end
        end

        context '相互フォロー関係がある場合' do
          before do
            viewer.follow(mutual_user)
            mutual_user.follow(viewer)
          end

          it '相互フォローのみの投稿が見える' do
            posts = Post.visible_to(viewer)
            expect(posts).to include(mutual_post)
          end
        end
      end

      context 'viewer が自分だけユーザーの投稿を見る場合' do
        it '自分だけの投稿は見えない' do
          posts = Post.visible_to(viewer)
          expect(posts).not_to include(private_post)
        end
      end

      context 'viewer が自分自身の投稿を見る場合' do
        it '自分の投稿は公開範囲に関わらず見える' do
          own_post = create(:post, user: viewer)
          viewer.update(post_visibility: :only_me)

          posts = Post.visible_to(viewer)
          expect(posts).to include(own_post)
        end
      end
    end

    describe '#visible_to?' do
      let(:post_owner) { create(:user, post_visibility: :only_me) }
      let(:test_post) { create(:post, user: post_owner) }

      context '投稿者本人が見る場合' do
        it 'true を返す' do
          expect(test_post.visible_to?(post_owner)).to be true
        end
      end

      context '全体公開の投稿' do
        before { post_owner.update(post_visibility: :everyone) }

        it '誰でも見られる' do
          expect(test_post.visible_to?(viewer)).to be true
        end
      end

      context '相互フォローのみの投稿' do
        before { post_owner.update(post_visibility: :mutual_followers) }

        it '相互フォロー関係がある場合は見られる' do
          viewer.follow(post_owner)
          post_owner.follow(viewer)

          expect(test_post.visible_to?(viewer)).to be true
        end

        it '相互フォロー関係がない場合は見られない' do
          expect(test_post.visible_to?(viewer)).to be false
        end
      end

      context '自分だけの投稿' do
        before { post_owner.update(post_visibility: :only_me) }

        it '他人には見られない' do
          expect(test_post.visible_to?(viewer)).to be false
        end
      end

      context 'リプライの場合' do
        let(:parent_owner) { create(:user, post_visibility: :everyone) }
        let(:parent_post) { create(:post, user: parent_owner) }
        let(:reply) { create(:post, user: post_owner, parent: parent_post) }

        before { post_owner.update(post_visibility: :only_me) }

        it '親投稿の作成者には見える' do
          expect(reply.visible_to?(parent_owner)).to be true
        end

        it '親投稿の作成者以外には見えない' do
          expect(reply.visible_to?(viewer)).to be false
        end
      end
    end
  end
end
