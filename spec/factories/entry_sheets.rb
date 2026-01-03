FactoryBot.define do
  factory :entry_sheet do
    association :user
    company_name { "株式会社サンプル" }
    status { :draft }
    visibility { :personal }
    deadline { 2.weeks.from_now }
  end
end
