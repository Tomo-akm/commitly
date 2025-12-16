require 'rails_helper'

RSpec.describe 'DirectMessages', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:room) { Room.between(user, other_user) }

  before { sign_in user, scope: :user }

  describe 'POST /direct_messages' do
    context '正常なパラメータの場合' do
      let(:valid_params) do
        { room_id: other_user.id, direct_message: { content: 'こんにちは' } }
      end

      it 'メッセージが作成される' do
        expect do
          post room_direct_messages_path(other_user), params: valid_params
        end.to change(DirectMessage, :count).by(1)
      end

      it '作成されたメッセージのユーザーがcurrent_userである' do
        post room_direct_messages_path(other_user), params: valid_params
        expect(DirectMessage.last.user).to eq(user)
      end

      it '作成されたメッセージがルームに紐づく' do
        post room_direct_messages_path(other_user), params: valid_params
        expect(DirectMessage.last.room).to eq(room)
      end

      it 'ルームを既読にする' do
        post room_direct_messages_path(other_user), params: valid_params
        entry = user.entries.find_by(room: room)
        expect(entry.last_read_at).not_to be_nil
      end
    end
  end
end
