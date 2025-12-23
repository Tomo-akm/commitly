FactoryBot.define do
  factory :intern_experience_content do
    company_name { Faker::Company.name }
    content { Faker::Lorem.paragraph }
  end
end
