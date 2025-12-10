FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@ie.u-ryukyu.ac.jp" }
    password { "password123" }
    password_confirmation { "password123" }
    name { Faker::Name.name }
    favorite_language { %w[Ruby Python JavaScript Go].sample }
    internship_count { rand(0..10) }
    personal_message { Faker::Lorem.sentence }

    trait :without_profile do
      favorite_language { nil }
      internship_count { nil }
      personal_message { nil }
    end
  end
end
