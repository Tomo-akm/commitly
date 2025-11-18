class Vault::DashboardController < ApplicationController
  before_action :authenticate_user!
  layout "vault"

  def index
    # 就活投稿から企業別の選考進捗を集計
    @company_progress = fetch_company_progress

    # ESの一覧（締切近い順）
    @upcoming_entry_sheets = current_user.entry_sheets
                                         .upcoming_deadline
                                         .limit(5)

    # 最近のES
    @recent_entry_sheets = current_user.entry_sheets
                                       .recent
                                       .limit(5)
  end

  private

  def fetch_company_progress
    # JobHuntingContentから企業別の選考状況を取得
    job_hunting_posts = current_user.posts
                                    .job_hunting
                                    .includes(:contentable)
                                    .order(created_at: :desc)

    # 企業名でグループ化して、最新の選考段階とresultを取得
    company_data = {}
    job_hunting_posts.each do |post|
      content = post.contentable
      company_name = content.normalized_company_name
      next if company_name.blank?

      # まだその企業のデータがない、または既存データより新しい場合に更新
      if company_data[company_name].nil? || company_data[company_name][:updated_at] < post.created_at
        company_data[company_name] = {
          company_name: content.company_name,
          normalized_name: company_name,
          selection_stage: content.selection_stage,
          selection_stage_ja: content.selection_stage_ja,
          result: content.result,
          result_ja: content.result_ja,
          updated_at: post.created_at
        }
      end
    end

    company_data.values.sort_by { |data| data[:updated_at] }.reverse
  end
end
