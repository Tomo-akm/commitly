class InternExperienceContent < ApplicationRecord
  include CompanyNameNormalizable

  has_one :post, as: :contentable, dependent: :destroy

  # プレゼンテーション用の定数
  TYPE_NAME = "intern_experience"
  TITLE = "インターン体験記 commit"
  SUCCESS_MESSAGE = "インターン体験記をpushしました"

  # 期間区分の定義
  enum :duration_type, {
    short_term: 1,    # 短期：1日〜1週間
    medium_term: 2,   # 中期：1週間〜1ヶ月
    long_term: 3      # 長期：1ヶ月以上
  }, prefix: true

  validates :company_name, presence: true, length: { maximum: 100 }
  validates :event_name, presence: true, length: { maximum: 100 }
  validates :duration_type, presence: true
  validates :content, presence: true, length: { maximum: 5000 }

  # Ransackの設定
  def self.ransackable_attributes(auth_object = nil)
    %w[company_name event_name duration_type content]
  end

  def self.duration_types_for_select
    [
      [ "短期（1日〜1週間）", "short_term" ],
      [ "中期（1週間〜1ヶ月）", "medium_term" ],
      [ "長期（1ヶ月以上）", "long_term" ]
    ]
  end

  def formatted_duration
    return nil if duration_type.blank?

    case duration_type
    when "short_term"
      "短期"
    when "medium_term"
      "中期"
    when "long_term"
      "長期"
    end
  end

  def type_name = TYPE_NAME
  def title = TITLE
  def success_message = SUCCESS_MESSAGE
end
