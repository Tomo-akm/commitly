class Vault::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  layout "vault"

  def show
    # 企業別の選考進捗を集計（公開投稿のみ）
    @company_progress = fetch_company_progress

    # 公開ESの一覧
    @public_entry_sheets = @user.entry_sheets
                                .publicly_visible
                                .recent
                                .page(params[:page])
                                .per(20)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def fetch_company_progress
    # JobHuntingContentから企業別の選考状況を取得（公開投稿のみ）
    job_hunting_posts = @user.posts
                             .publicly_visible
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
