require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      tag = build(:tag)
      expect(tag).to be_valid
    end

    it 'requires a name' do
      tag = build(:tag, name: nil)
      expect(tag).not_to be_valid
    end

    it 'requires a unique name' do
      create(:tag, name: 'ruby')
      tag = build(:tag, name: 'ruby')
      expect(tag).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many posts through post_tags' do
      association = described_class.reflect_on_association(:posts)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:post_tags)
    end
  end
end
