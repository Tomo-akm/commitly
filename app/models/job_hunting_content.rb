class JobHuntingContent < ApplicationRecord
  has_one :post, as: :contentable, dependent: :destroy

  # enum定義
  enum :selection_stage, {
    es: 0,
    first_interview: 1,
    second_interview: 2,
    final_interview: 3,
    other: 4
  }, prefix: true

  enum :result, {
    passed: 0,
    failed: 1,
    pending: 2
  }, prefix: true

  validates :company_name, presence: true, length: { maximum: 100 }
  validates :selection_stage, presence: true, inclusion: { in: selection_stages.keys }
  validates :result, presence: true, inclusion: { in: results.keys }
  validates :content, presence: true, length: { maximum: 5000 }

  # Ransackの設定
  def self.ransackable_attributes(auth_object = nil)
    %w[company_name selection_stage result content]
  end

  # 日本語表示用のヘルパーメソッド
  def selection_stage_ja
    I18n.t("activerecord.attributes.job_hunting_content.selection_stages.#{selection_stage}")
  end

  def result_ja
    I18n.t("activerecord.attributes.job_hunting_content.results.#{result}")
  end

  # セレクトボックス用の選択肢
  def self.selection_stages_for_select
    selection_stages.keys.map do |stage|
      [ I18n.t("activerecord.attributes.job_hunting_content.selection_stages.#{stage}"), stage ]
    end
  end

  def self.results_for_select
    results.keys.map do |result_value|
      [ I18n.t("activerecord.attributes.job_hunting_content.results.#{result_value}"), result_value ]
    end
  end

  # 企業名から法人格を除去して正規化
  def normalized_company_name
    return "" if company_name.blank?

    normalized = company_name.strip
    # 前方の法人格を除去
    normalized = normalized.gsub(/^(株式会社|有限会社|合同会社|一般社団法人|一般財団法人|公益社団法人|公益財団法人)\s*/, "")
    # 後方の法人格を除去
    normalized = normalized.gsub(/\s*(株式会社|有限会社|合同会社|一般社団法人|一般財団法人|公益社団法人|公益財団法人)$/, "")
    # (株)などの省略形を除去
    normalized = normalized.gsub(/^\(株\)\s*/, "")
    normalized = normalized.gsub(/\s*\(株\)$/, "")
    normalized.strip
  end
end
