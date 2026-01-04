require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'requires an email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it 'requires a unique email' do
      create(:user, email: 'test@ie.u-ryukyu.ac.jp')
      user = build(:user, email: 'test@ie.u-ryukyu.ac.jp')
      expect(user).not_to be_valid
    end

    it 'requires a password' do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
    end

    describe 'account_id' do
      it '有効なaccount_idの場合は有効' do
        user = build(:user, account_id: 'valid_user123')
        expect(user).to be_valid
      end

      it '空欄の場合は無効' do
        user = build(:user, account_id: nil)
        expect(user).not_to be_valid
      end

      it '重複するaccount_idの場合は無効' do
        create(:user, account_id: 'duplicate_user')
        user = build(:user, account_id: 'duplicate_user')
        expect(user).not_to be_valid
      end

      it '2文字以下の場合は無効' do
        user = build(:user, account_id: 'ab')
        expect(user).not_to be_valid
      end

      it '3文字の場合は有効（最小値）' do
        user = build(:user, account_id: 'abc')
        expect(user).to be_valid
      end

      it '20文字の場合は有効（最大値）' do
        user = build(:user, account_id: 'a' * 20)
        expect(user).to be_valid
      end

      it '21文字以上の場合は無効' do
        user = build(:user, account_id: 'a' * 21)
        expect(user).not_to be_valid
      end

      it '英数字とアンダースコアのみの場合は有効' do
        user = build(:user, account_id: 'user_123_ABC')
        expect(user).to be_valid
      end

      it 'ハイフンを含む場合は無効' do
        user = build(:user, account_id: 'user-123')
        expect(user).not_to be_valid
      end

      it 'スペースを含む場合は無効' do
        user = build(:user, account_id: 'user 123')
        expect(user).not_to be_valid
      end

      it '特殊文字を含む場合は無効' do
        user = build(:user, account_id: 'user@123')
        expect(user).not_to be_valid
      end
    end

    describe 'graduation_year' do
      it '有効な卒業年度（2026年）の場合は有効' do
        user = build(:user, graduation_year: 2026)
        expect(user).to be_valid
      end

      it '範囲外の卒業年度（1999年）の場合は無効' do
        user = build(:user, graduation_year: 1999)
        expect(user).not_to be_valid
      end

      it '範囲外の卒業年度（2150年）の場合は無効' do
        user = build(:user, graduation_year: 2150)
        expect(user).not_to be_valid
      end

      it '空欄の場合は有効（任意項目）' do
        user = build(:user, graduation_year: nil)
        expect(user).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'has many posts' do
      association = described_class.reflect_on_association(:posts)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many likes' do
      association = described_class.reflect_on_association(:likes)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many liked_posts through likes' do
      association = described_class.reflect_on_association(:liked_posts)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:likes)
      expect(association.options[:source]).to eq(:post)
    end
  end

  describe '#posts' do
    it 'returns posts created by the user' do
      user = create(:user)
      post1 = create(:post, user: user)
      post2 = create(:post, user: user)
      other_post = create(:post)

      expect(user.posts).to include(post1, post2)
      expect(user.posts).not_to include(other_post)
    end
  end

  describe '#liked_posts' do
    it 'returns posts liked by the user' do
      user = create(:user)
      other_user = create(:user)
      liked_post1 = create(:post, user: other_user)
      liked_post2 = create(:post, user: other_user)
      not_liked_post = create(:post, user: other_user)

      create(:like, user: user, post: liked_post1)
      create(:like, user: user, post: liked_post2)

      expect(user.liked_posts).to include(liked_post1, liked_post2)
      expect(user.liked_posts).not_to include(not_liked_post)
    end

    it 'returns empty array when user has not liked any posts' do
      user = create(:user)
      create(:post)

      expect(user.liked_posts).to be_empty
    end
  end

  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'e215700@ie.u-ryukyu.ac.jp',
          name: '山田太郎'
        }
      })
    end

    context '新規ユーザーの場合' do
      it 'ユーザーを作成する' do
        expect {
          User.from_omniauth(auth)
        }.to change(User, :count).by(1)
      end

      it '正しい属性を設定する' do
        user = User.from_omniauth(auth)
        expect(user.email).to eq('e215700@ie.u-ryukyu.ac.jp')
        expect(user.name).to eq('山田太郎')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
      end

      it 'ランダムなパスワードを設定する' do
        user = User.from_omniauth(auth)
        expect(user.encrypted_password).to be_present
      end

      it 'internship_countを0で初期化する' do
        user = User.from_omniauth(auth)
        expect(user.internship_count).to eq(0)
      end
    end

    context '既存ユーザーの場合' do
      it '新規作成しない' do
        User.from_omniauth(auth)
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end

      it '既存のユーザーを返す' do
        first_user = User.from_omniauth(auth)
        second_user = User.from_omniauth(auth)
        expect(first_user.id).to eq(second_user.id)
      end
    end

    context 'nameがない場合' do
      let(:auth_without_name) do
        OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: '987654321',
          info: {
            email: 'test@cs.u-ryukyu.ac.jp',
            name: ''
          }
        })
      end

      it 'emailの@前の部分をnameとする' do
        user = User.from_omniauth(auth_without_name)
        expect(user.name).to eq('test')
      end
    end

    context '一般的なメールアドレスの場合' do
      let(:gmail_auth) do
        OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: '111222333',
          info: {
            email: 'user@gmail.com',
            name: 'テストユーザー'
          }
        })
      end

      it 'Gmailアドレスでもユーザーを作成できる' do
        expect {
          User.from_omniauth(gmail_auth)
        }.to change(User, :count).by(1)
      end

      it '正しい属性を設定する' do
        user = User.from_omniauth(gmail_auth)
        expect(user.email).to eq('user@gmail.com')
        expect(user.name).to eq('テストユーザー')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('111222333')
      end
    end
  end

  describe 'email validation' do
    context '様々なメールアドレスの場合' do
      it '琉球大学のメールアドレスを許可する' do
        user = build(:user, email: 'e215700@eve.u-ryukyu.ac.jp', password: 'password123')
        expect(user).to be_valid
      end

      it 'Gmailアドレスを許可する' do
        user = build(:user, email: 'test@gmail.com', password: 'password123')
        expect(user).to be_valid
      end

      it 'その他のメールアドレスを許可する' do
        user = build(:user, email: 'user@example.com', password: 'password123')
        expect(user).to be_valid
      end
    end
  end

  describe '#intern_participations_count' do
    let(:user) { create(:user) }

    it 'インターン体験記がない場合は0を返すこと' do
      expect(user.intern_participations_count).to eq(0)
    end

    it '同じ企業・同じイベント名の投稿は1回としてカウントされること' do
      intern_content1 = build(:intern_experience_content, company_name: "株式会社テスト", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content1)

      intern_content2 = build(:intern_experience_content, company_name: "株式会社テスト", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content2)

      expect(user.intern_participations_count).to eq(1)
    end

    it '異なる企業名の投稿は別々にカウントされること' do
      intern_content1 = build(:intern_experience_content, company_name: "株式会社A", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content1)

      intern_content2 = build(:intern_experience_content, company_name: "株式会社B", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content2)

      expect(user.intern_participations_count).to eq(2)
    end

    it '同じ企業でも異なるイベント名の投稿は別々にカウントされること' do
      intern_content1 = build(:intern_experience_content, company_name: "株式会社テスト", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content1)

      intern_content2 = build(:intern_experience_content, company_name: "株式会社テスト", event_name: "ウィンターインターン")
      create(:post, user: user, contentable: intern_content2)

      expect(user.intern_participations_count).to eq(2)
    end

    it '他のユーザーの投稿はカウントしないこと' do
      other_user = create(:user)

      intern_content1 = build(:intern_experience_content, company_name: "株式会社テスト", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content1)

      intern_content2 = build(:intern_experience_content, company_name: "株式会社テスト", event_name: "サマーインターン")
      create(:post, user: other_user, contentable: intern_content2)

      expect(user.intern_participations_count).to eq(1)
    end

    it '複数の異なる企業・イベントの組み合わせを正しくカウントすること' do
      intern_content1 = build(:intern_experience_content, company_name: "株式会社A", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content1)

      intern_content2 = build(:intern_experience_content, company_name: "株式会社A", event_name: "ウィンターインターン")
      create(:post, user: user, contentable: intern_content2)

      intern_content3 = build(:intern_experience_content, company_name: "株式会社B", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content3)

      # 同じ組み合わせの重複
      intern_content4 = build(:intern_experience_content, company_name: "株式会社A", event_name: "サマーインターン")
      create(:post, user: user, contentable: intern_content4)

      expect(user.intern_participations_count).to eq(3)
    end
  end

  describe 'post_visibility enum' do
    it 'デフォルトで everyone が設定される' do
      user = create(:user)
      expect(user.post_visibility).to eq('everyone')
      expect(user.everyone?).to be true
    end

    it 'mutual_followers に設定できる' do
      user = create(:user, post_visibility: :mutual_followers)
      expect(user.post_visibility).to eq('mutual_followers')
      expect(user.mutual_followers?).to be true
    end

    it 'only_me に設定できる' do
      user = create(:user, post_visibility: :only_me)
      expect(user.post_visibility).to eq('only_me')
      expect(user.only_me?).to be true
    end
  end

  describe '#mutual_follow?' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }

    context '相互フォロー関係の場合' do
      before do
        user_a.follow(user_b)
        user_b.follow(user_a)
      end

      it 'true を返す' do
        expect(user_a.mutual_follow?(user_b)).to be true
        expect(user_b.mutual_follow?(user_a)).to be true
      end
    end

    context 'Aだけがフォローしている場合' do
      before do
        user_a.follow(user_b)
      end

      it 'false を返す' do
        expect(user_a.mutual_follow?(user_b)).to be false
        expect(user_b.mutual_follow?(user_a)).to be false
      end
    end

    context 'フォロー関係がない場合' do
      it 'false を返す' do
        expect(user_a.mutual_follow?(user_b)).to be false
        expect(user_b.mutual_follow?(user_a)).to be false
      end
    end
  end

  describe '#public_entry_sheets_count' do
    let(:user) { create(:user) }

    it '公開ESの数を返す' do
      create(:entry_sheet, user: user, visibility: :shared)
      create(:entry_sheet, user: user, visibility: :shared)
      create(:entry_sheet, user: user, visibility: :personal)

      expect(user.public_entry_sheets_count).to eq(2)
    end

    it '公開ESがない場合は0を返す' do
      create(:entry_sheet, user: user, visibility: :personal)

      expect(user.public_entry_sheets_count).to eq(0)
    end
  end
end
