FactoryBot.define do
  factory :general_content do
    content { Faker::Lorem.paragraph }
  end
end
