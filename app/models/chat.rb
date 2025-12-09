class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :chattable, polymorphic: true, optional: true
  has_many :messages, dependent: :destroy

  validates :user, presence: true
end
