class Vault::SharedController < Vault::BaseController
  before_action :set_user

  def show
    # 企業別の選考進捗を集計（公開投稿のみ）
    @company_progress = fetch_company_progress(@user, public_only: true)

    # 公開ESの一覧
    @public_entry_sheets = @user.entry_sheets
                                .publicly_visible
                                .recent
                                .page(params[:page])
                                .per(20)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to vault_root_path, alert: "ユーザーが見つかりません"
  end
end
