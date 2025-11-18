class Vault::EntrySheetItemTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: [ :show, :edit, :update, :destroy, :use ]
  before_action :check_ownership, only: [ :show, :edit, :update, :destroy, :use ]
  layout "vault"

  def index
    @templates = current_user.entry_sheet_item_templates
                             .order(created_at: :desc)
                             .page(params[:page])
                             .per(20)

    # タグでフィルタリング
    if params[:tag].present?
      @templates = @templates.by_tag(params[:tag])
    end

    # 利用可能なタグ一覧
    @available_tags = current_user.entry_sheet_item_templates
                                  .select(:tag)
                                  .distinct
                                  .pluck(:tag)
                                  .sort
  end

  def show
  end

  def new
    @template = current_user.entry_sheet_item_templates.build
  end

  def edit
  end

  def create
    @template = current_user.entry_sheet_item_templates.build(template_params)

    if @template.save
      redirect_to vault_entry_sheet_item_templates_path, notice: "テンプレートを作成しました"
    else
      flash.now[:alert] = "テンプレートの作成に失敗しました: #{@template.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @template.update(template_params)
      redirect_to vault_entry_sheet_item_templates_path, notice: "テンプレートを更新しました"
    else
      flash.now[:alert] = "テンプレートの更新に失敗しました: #{@template.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy!
    redirect_to vault_entry_sheet_item_templates_path, notice: "テンプレートを削除しました", status: :see_other
  end

  def use
    # このアクションはJavaScript（今後実装）で使う予定
    # テンプレートをES項目に読み込む機能
    respond_to do |format|
      format.json { render json: @template }
    end
  end

  private

  def set_template
    @template = EntrySheetItemTemplate.find(params[:id])
  end

  def check_ownership
    unless @template.user == current_user
      redirect_to vault_entry_sheet_item_templates_path, alert: "このテンプレートにアクセスする権限がありません"
    end
  end

  def template_params
    params.expect(entry_sheet_item_template: [ :tag, :title, :content ])
  end
end
