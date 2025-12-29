FactoryBot.define do
  factory :intern_experience_content do
    company_name { Faker::Company.name }
    event_name { "#{%w[サマー ウィンター オータム スプリング].sample}インターンシップ#{Date.today.year}" }
    duration_type { %i[short_term medium_term long_term].sample }
    content { Faker::Lorem.paragraph }
  end
end
