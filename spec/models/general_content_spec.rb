require 'rails_helper'

RSpec.describe GeneralContent, type: :model do
  describe 'バリデーション' do
    it '有効な属性の場合、有効であること' do
      general_content = build(:general_content)
      expect(general_content).to be_valid
    end

    it 'contentが必須であること' do
      general_content = build(:general_content, content: nil)
      expect(general_content).not_to be_valid
      expect(general_content.errors[:content]).to include("を入力してください")
    end

    it 'contentが5000文字を超える場合、無効であること' do
      general_content = build(:general_content, content: 'a' * 5001)
      expect(general_content).not_to be_valid
      expect(general_content.errors[:content]).to include("は5000文字以内で入力してください")
    end

    it 'contentが5000文字以内の場合、有効であること' do
      general_content = build(:general_content, content: 'a' * 5000)
      expect(general_content).to be_valid
    end
  end

  describe '関連' do
    it 'postと1対1の関連を持つこと' do
      association = described_class.reflect_on_association(:post)
      expect(association.macro).to eq(:has_one)
      expect(association.options[:as]).to eq(:contentable)
    end

    it '削除時に関連するpostも削除されること' do
      post = create(:post, :general)
      general_content = post.contentable

      expect { general_content.destroy }.to change(Post, :count).by(-1)
    end
  end
end
