module CompanyNameNormalizable
  extend ActiveSupport::Concern

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

  # 表示用の企業名（正規化されたタグ名を優先、なければ正規化して返す）
  def display_company_name
    # タグが保存されていればそれを使用（計算不要で高速）
    post&.tags&.first&.name || normalized_company_name
  end
end
