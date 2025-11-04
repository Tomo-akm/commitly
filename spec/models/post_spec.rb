require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      post = build(:post)
      expect(post).to be_valid
    end

    it 'requires content' do
      post = build(:post, content: nil)
      expect(post).not_to be_valid
    end

    it 'requires a user' do
      post = build(:post, user: nil)
      expect(post).not_to be_valid
    end

    it 'is invalid when content exceeds 280 characters' do
      post = build(:post, content: 'a' * 281)
      expect(post).not_to be_valid
      expect(post.errors[:content]).to include('は280文字以内で入力してください')
    end

    it 'is valid when content is exactly 280 characters' do
      post = build(:post, content: 'a' * 280)
      expect(post).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to parent (optional)' do
      association = described_class.reflect_on_association(:parent)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be_truthy
    end

    it 'has many replies' do
      association = described_class.reflect_on_association(:replies)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
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

  describe 'reply functionality' do
    let(:user) { create(:user) }
    let(:parent_post) { create(:post, user: user) }
    let(:reply_post) { create(:post, user: user, parent: parent_post) }

    it 'can create a reply to a post' do
      expect(reply_post.parent).to eq(parent_post)
      expect(parent_post.replies).to include(reply_post)
    end

    it 'can have nested replies (reply to a reply)' do
      nested_reply = create(:post, user: user, parent: reply_post)
      expect(nested_reply.parent).to eq(reply_post)
      expect(reply_post.replies).to include(nested_reply)
    end

    it 'deletes replies when parent post is deleted' do
      reply_post # ensure reply exists
      expect { parent_post.destroy }.to change(Post, :count).by(-2) # parent + 1 reply
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:top_level_post1) { create(:post, user: user) }
    let!(:top_level_post2) { create(:post, user: user) }
    let!(:reply1) { create(:post, user: user, parent: top_level_post1) }
    let!(:reply2) { create(:post, user: user, parent: top_level_post1) }

    describe '.top_level' do
      it 'returns only top level posts (not replies)' do
        expect(Post.top_level).to include(top_level_post1, top_level_post2)
        expect(Post.top_level).not_to include(reply1, reply2)
      end
    end

    describe '.replies_only' do
      it 'returns only replies (not top level posts)' do
        expect(Post.replies_only).to include(reply1, reply2)
        expect(Post.replies_only).not_to include(top_level_post1, top_level_post2)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:parent_post) { create(:post, user: user) }
    let(:reply_post) { create(:post, user: user, parent: parent_post) }

    describe '#reply?' do
      it 'returns true for a reply' do
        expect(reply_post.reply?).to be true
      end

      it 'returns false for a top level post' do
        expect(parent_post.reply?).to be false
      end
    end

    describe '#top_level?' do
      it 'returns true for a top level post' do
        expect(parent_post.top_level?).to be true
      end

      it 'returns false for a reply' do
        expect(reply_post.top_level?).to be false
      end
    end
  end
end
