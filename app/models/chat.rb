class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id

  belongs_to :user
  belongs_to :model, optional: true
  belongs_to :chattable, polymorphic: true, optional: true

  validates :user, presence: true
end
