class Vault::EntrySheetsController < Vault::BaseController
  before_action :set_entry_sheet, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]

  def index
    @entry_sheets = current_user.entry_sheets
                                .order(created_at: :desc)
                                .page(params[:page])
                                .per(20)
  end

  def show
    @entry_sheet_items = @entry_sheet.entry_sheet_items.ordered
  end

  def new
    @entry_sheet = current_user.entry_sheets.build
    @entry_sheet.entry_sheet_items.build
    @templates = current_user.entry_sheet_item_templates.order(:tag, :created_at)
  end

  def edit
    @templates = current_user.entry_sheet_item_templates.order(:tag, :created_at)
    # 項目が1つもない場合は空の項目を追加（項目追加機能のため）
    @entry_sheet.entry_sheet_items.build if @entry_sheet.entry_sheet_items.empty?
  end

  def create
    @entry_sheet = current_user.entry_sheets.build(entry_sheet_params)

    if @entry_sheet.save
      redirect_to vault_entry_sheet_path(@entry_sheet), notice: "ESを作成しました。つぶやきで共有してレビューをもらおう！"
    else
      flash.now[:alert] = "ESの作成に失敗しました: #{@entry_sheet.errors.full_messages.join(', ')}"
      @templates = current_user.entry_sheet_item_templates.order(:tag, :created_at)
      @entry_sheet.entry_sheet_items.build if @entry_sheet.entry_sheet_items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @entry_sheet.update(entry_sheet_params)
      redirect_to vault_entry_sheet_path(@entry_sheet), notice: "ESを更新しました"
    else
      flash.now[:alert] = "ESの更新に失敗しました: #{@entry_sheet.errors.full_messages.join(', ')}"
      @templates = current_user.entry_sheet_item_templates.order(:tag, :created_at)
      @entry_sheet.entry_sheet_items.build if @entry_sheet.entry_sheet_items.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry_sheet.destroy!
    redirect_to vault_entry_sheets_path, notice: "ESを削除しました", status: :see_other
  end

  private

  def set_entry_sheet
    @entry_sheet = EntrySheet.includes(entry_sheet_items: :chat).find(params[:id])

    # 閲覧権限チェック（showアクション用）
    unless @entry_sheet.viewable_by?(current_user)
      redirect_to vault_root_path, alert: "このESは公開されていません"
    end
  end

  # 所有者チェック（edit/update/destroyアクション用）
  def authorize_owner!
    unless @entry_sheet.user_id == current_user.id
      redirect_to vault_root_path, alert: "他のユーザーのESは編集できません"
    end
  end

  def entry_sheet_params
    params.require(:entry_sheet).permit(
      :company_name,
      :deadline,
      :status,
      :submitted_at,
      :visibility,
      entry_sheet_items_attributes: [
        :id,
        :title,
        :content,
        :char_limit,
        :position,
        :entry_sheet_item_template_id,
        :_destroy
      ]
    )
  end
end
