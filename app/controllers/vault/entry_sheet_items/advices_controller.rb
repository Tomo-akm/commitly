module Vault
  module EntrySheetItems
    class AdvicesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_entry_sheet_item
      before_action :validate_advice_params, only: :create
      before_action :find_model, only: :create

      def create
        create_chat_with_model
        enqueue_advice_job
        respond_to(&:turbo_stream)
      end

      def destroy
        return render_error("添削結果が見つかりません") unless @entry_sheet_item.chat

        destroy_chat
        respond_to(&:turbo_stream)
      end

      private

      def set_entry_sheet_item
        @entry_sheet_item = EntrySheetItem.find(params[:entry_sheet_item_id])
        authorize_entry_sheet_item!
      end

      def authorize_entry_sheet_item!
        return if @entry_sheet_item.entry_sheet.user_id == current_user.id

        redirect_to vault_root_path, alert: "アクセス権限がありません" and return
      end

      def validate_advice_params
        @advice_params = {
          title: params[:current_title],
          content: params[:current_content],
          char_limit: params[:current_char_limit]
        }

        if @advice_params[:title].blank? || @advice_params[:content].blank?
          redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet), alert: "入力内容が不足しています" and return
        end

        if @advice_params[:title].length > 100
          redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet), alert: "タイトルが長すぎます。100文字以内で入力してください。" and return
        end

        if @advice_params[:content].length > 2000
          redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet), alert: "内容が長すぎます。2000文字以内で入力してください。" and return
        end
      end

      def find_model
        @model = find_available_model(params[:model_id])
        unless @model
          redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet), alert: "利用可能なAIモデルがありません。APIキーを設定してください。" and return
        end
      end

      def find_available_model(model_id)
        available_models = Model.available_for_user(current_user)
        model_id.present? ? available_models.find_by(id: model_id) : available_models.first
      end

      def create_chat_with_model
        ActiveRecord::Base.transaction do
          @entry_sheet_item.chat&.destroy
          @entry_sheet_item.create_chat!(
            user: current_user,
            model: @model,
            title: "#{@advice_params[:title]}の添削"
          )
        end
        @entry_sheet_item.reload
      end

      def enqueue_advice_job
        EntrySheetAdviceJob.perform_later(
          @entry_sheet_item.id,
          current_user.id,
          @model.id,
          @advice_params[:title],
          @advice_params[:content],
          @advice_params[:char_limit]
        )
      end

      def destroy_chat
        @chat = @entry_sheet_item.chat
        @chat.destroy
        @entry_sheet_item.reload
      end

      def render_error(message)
        @error = message
        respond_to(&:turbo_stream)
      end
    end
  end
end
