require 'rails_helper'

RSpec.describe DirectMessage, type: :model do
  describe 'associations' do
    it 'belongs to room' do
      expect(described_class.reflect_on_association(:room).macro).to eq(:belongs_to)
    end

    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'validates presence of content' do
      direct_message = build(:direct_message, content: nil)
      expect(direct_message).not_to be_valid
      expect(direct_message.errors[:content]).to include("を入力してください")
    end

    it 'validates length of content' do
      direct_message = build(:direct_message, content: 'a' * 5001)
      expect(direct_message).not_to be_valid
      expect(direct_message.errors[:content]).to include('は5000文字以内で入力してください')
    end
  end
end
