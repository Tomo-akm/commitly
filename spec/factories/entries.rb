FactoryBot.define do
  factory :entry do
    association :user
    association :room
    last_read_at { nil }
  end
end
