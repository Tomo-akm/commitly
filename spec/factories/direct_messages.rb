FactoryBot.define do
  factory :direct_message do
    association :room
    association :user
    content { "テストメッセージ" }
  end
end
