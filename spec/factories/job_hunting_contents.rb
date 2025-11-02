FactoryBot.define do
  factory :job_hunting_content do
    company_name { Faker::Company.name }
    selection_stage { :es }
    result { :pending }
    content { Faker::Lorem.paragraph }
  end
end