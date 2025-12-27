FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@ie.u-ryukyu.ac.jp" }
    sequence(:account_id) { |n| "user_#{n}_#{SecureRandom.alphanumeric(8)}" }
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

    trait :oauth_user do
      provider { "google_oauth2" }
      uid { SecureRandom.uuid }
      password { nil }
      password_confirmation { nil }
    end
  end
end
