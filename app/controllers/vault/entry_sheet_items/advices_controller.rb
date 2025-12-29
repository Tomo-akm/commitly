module Vault
  module EntrySheetItems
    class AdvicesController < ApplicationController
      MAX_TITLE_LENGTH = 100
      MAX_CONTENT_LENGTH = 2000

      before_action :authenticate_user!
      before_action :set_entry_sheet_item
      before_action :validate_advice_params, only: :create
      before_action :check_usage_limit, only: :create

      def create
        create_chat_with_model

        EntrySheetAdviceJob.perform_later(
          @entry_sheet_item.id,
          current_user.id,
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

      def usage_stats
        render json: LlmUsage.stats(current_user)
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

        return if valid_advice_params?

        redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet),
                    alert: advice_validation_error_message and return
      end

      def valid_advice_params?
        @advice_params[:title].present? &&
          @advice_params[:content].present? &&
          @advice_params[:title].length <= MAX_TITLE_LENGTH &&
          @advice_params[:content].length <= MAX_CONTENT_LENGTH
      end

      def advice_validation_error_message
        return "入力内容が不足しています" if @advice_params[:title].blank? || @advice_params[:content].blank?
        return "タイトルが長すぎます。#{MAX_TITLE_LENGTH}文字以内で入力してください。" if @advice_params[:title].length > MAX_TITLE_LENGTH

        "内容が長すぎます。#{MAX_CONTENT_LENGTH}文字以内で入力してください。"
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

      def check_usage_limit
        LlmUsage.check_and_reserve!(current_user)
      rescue LlmUsage::LimitExceededError
        redirect_to edit_vault_entry_sheet_path(@entry_sheet_item.entry_sheet),
                    alert: "本日の利用上限に達しました。翌日0時にリセットされます。" and return
      end

      def render_error(message)
        @error = message
        respond_to(&:turbo_stream)
      end
    end
  end
end
