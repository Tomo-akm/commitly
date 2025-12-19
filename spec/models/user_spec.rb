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
end
