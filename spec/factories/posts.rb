FactoryBot.define do
  factory :post do
    association :user
    association :contentable, factory: :general_content

    trait :general do
      association :contentable, factory: :general_content
    end

    trait :job_hunting do
      association :contentable, factory: :job_hunting_content
    end

    trait :intern_experience do
      association :contentable, factory: :intern_experience_content
    end

    trait :with_tags do
      after(:create) do |post|
        create_list(:tag, 3, posts: [ post ])
      end
    end
  end
end
