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
end
