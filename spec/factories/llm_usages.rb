FactoryBot.define do
  factory :llm_usage do
    association :user
    usage_date { Date.current }
    count { 0 }

    trait :at_limit do
      count { LlmUsage::DAILY_LIMIT }
    end

    trait :near_limit do
      count { LlmUsage::DAILY_LIMIT - 1 }
    end

    trait :yesterday do
      usage_date { Date.yesterday }
    end
  end
end
