class JobHuntingContent < ApplicationRecord
  include CompanyNameNormalizable

  has_one :post, as: :contentable, dependent: :destroy

  # プレゼンテーション用の定数
  TYPE_NAME = "job_hunting"
  TITLE = "就活記録 commit"
  SUCCESS_MESSAGE = "就活記録をpushしました"

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

  # プレゼンテーション用メソッド（ポリモーフィックアクセス用）
  def type_name = TYPE_NAME
  def title = TITLE
  def success_message = SUCCESS_MESSAGE
end
