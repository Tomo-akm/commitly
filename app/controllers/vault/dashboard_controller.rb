class Vault::DashboardController < Vault::BaseController
  def index
    # 就活投稿から企業別の選考進捗を集計（全投稿）
    @company_progress = fetch_company_progress(current_user)

    # ESの一覧（締切近い順）
    @upcoming_entry_sheets = current_user.entry_sheets
                                         .upcoming_deadline
                                         .limit(5)

    # 最近のES
    @recent_entry_sheets = current_user.entry_sheets
                                       .recent
                                       .limit(5)
  end
end
