class Room < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :users, through: :entries
  has_many :direct_messages, dependent: :destroy

  # 2人のユーザー間のルームを取得または作成
  def self.between(user1, user2)
    room = joins(:entries)
             .where(entries: { user_id: [ user1.id, user2.id ] })
             .group("rooms.id")
             .having("COUNT(entries.id) = 2")
             .first

    room || create_between(user1, user2)
  end

  def self.create_between(user1, user2)
    transaction do
      room = create!
      room.entries.create!(user: user1)
      room.entries.create!(user: user2)
      room
    end
  end

  # 相手のユーザーを取得
  def other_user(current_user)
    users.where.not(id: current_user.id).first
  end

  # 最新メッセージ
  def latest_message
    direct_messages.order(created_at: :desc).first
  end
end
