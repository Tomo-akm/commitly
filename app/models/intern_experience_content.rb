class InternExperienceContent < ApplicationRecord
  include CompanyNameNormalizable

  has_one :post, as: :contentable, dependent: :destroy

  # プレゼンテーション用の定数
  TYPE_NAME = "intern_experience"
  TITLE = "インターン体験記 commit"
  SUCCESS_MESSAGE = "インターン体験記をpushしました"

  # 期間のプリセット定義（日数）
  DURATION_PRESETS = {
    one_day: 1,
    three_days: 3,
    one_week: 7,
    two_weeks: 14,
    one_month: 30,
    three_months: 90,
    six_months: 180
  }.freeze

  validates :company_name, presence: true, length: { maximum: 100 }
  validates :event_name, length: { maximum: 100 }, allow_blank: true
  validates :duration_days, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validates :content, presence: true, length: { maximum: 5000 }

  # Ransackの設定
  def self.ransackable_attributes(auth_object = nil)
    %w[company_name event_name duration_days content]
  end

  def self.duration_presets_for_select
    [
      ["1日", DURATION_PRESETS[:one_day]],
      ["3日間", DURATION_PRESETS[:three_days]],
      ["1週間", DURATION_PRESETS[:one_week]],
      ["2週間", DURATION_PRESETS[:two_weeks]],
      ["1ヶ月", DURATION_PRESETS[:one_month]],
      ["3ヶ月", DURATION_PRESETS[:three_months]],
      ["6ヶ月", DURATION_PRESETS[:six_months]]
    ]
  end

  def formatted_duration
    return nil if duration_days.blank?

    case duration_days
    when 1
      "1日"
    when 3
      "3日間"
    when 7
      "1週間"
    when 14
      "2週間"
    when 30
      "1ヶ月"
    when 90
      "3ヶ月"
    when 180
      "6ヶ月以上"
    end
  end

  def type_name = TYPE_NAME
  def title = TITLE
  def success_message = SUCCESS_MESSAGE
end
