FactoryBot.define do
  factory :reply do
    content { "MyText" }
    user { nil }
    post { nil }
    parent { nil }
  end
end
