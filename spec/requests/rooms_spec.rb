require 'rails_helper'

RSpec.describe 'Rooms', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:room) { Room.between(user, other_user) }

  before { sign_in user, scope: :user }

  describe 'POST /rooms' do
    it 'ルームが作成される' do
      new_user = create(:user)
      expect do
        post rooms_path, params: { user_id: new_user.id }
      end.to change(Room, :count).by(1)
    end
  end

  describe 'POST /rooms/:id/mark_as_read' do
    before do
      room
      create(:direct_message, room: room, user: other_user, content: 'テストメッセージ')
    end

    it 'ルームが既読になる' do
      post mark_as_read_room_path(other_user)
      entry = user.entries.find_by(room: room)
      expect(entry.last_read_at).not_to be_nil
    end
  end
end
