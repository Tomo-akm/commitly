module Vault
  module EntrySheetItems
    class AdvicesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_entry_sheet_item
      before_action :validate_advice_params, only: :create
      before_action :find_model, only: :create

      def create
        create_chat_with_model

        EntrySheetAdviceJob.perform_later(
          @entry_sheet_item.id,
          current_user.id,
          @model.id,
          @advice_params[:title],
          @advice_params[:content],
          @advice_params[:char_limit]
        )

        respond_to(&:turbo_stream)
      end

      def destroy
        return render_error("添削結果が見つかりません") unless @entry_sheet_item.chat

        @entry_sheet_item.chat.destroy
        @entry_sheet_item.reload
        respond_to(&:turbo_stream)
      end

      private

      def set_entry_sheet_item
        @entry_sheet_item = EntrySheetItem.find(params[:entry_sheet_item_id])
        return if @entry_sheet_item.entry_sheet.user_id == current_user.id

        redirect_to vault_root_path, alert: "アクセス権限がありません" and return
      end

      def validate_advice_params
        @advice_params = {
          title: params[:current_title],
          content: params[:current_content],
          char_limit: params[:current_char_limit]
        }

        return if @advice_params[:title].present? &&
                  @advice_params[:content].present? &&
                  @advice_params[:title].length <= 100 &&
                  @advice_params[:content].length <= 2000

        error_message = if @advice_params[:title].blank? || @advice_params[:content].blank?
                          "入力内容が不足しています"
        elsif @advice_params[:title].length > 100
                          "タイトルが長すぎます。100文字以内で入力してください。"
        else
                          "内容が長すぎます。2000文字以内で入力してください。"
        end

        redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet), alert: error_message and return
      end

      def find_model
        return if params[:model_id].blank? &&
                  redirect_to(edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet), alert: "AIモデルを選択してください")

        @model = Model.available_for_user(current_user).find_by(id: params[:model_id])
        return if @model

        redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet), alert: "AIモデルを選択してください" and return
      end

      # Helper methods
      def create_chat_with_model
        ActiveRecord::Base.transaction do
          @entry_sheet_item.chat&.destroy
          @entry_sheet_item.create_chat!(
            user: current_user,
            title: "#{@advice_params[:title]}の添削"
          )
        end
        @entry_sheet_item.reload
      end

      def render_error(message)
        @error = message
        respond_to(&:turbo_stream)
      end
    end
  end
end
