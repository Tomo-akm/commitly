# frozen_string_literal: true

module VaultHelper
  # ステータスバッジを表示（重複削減の要）
  def entry_sheet_status_badge(entry_sheet, size: :md)
    status_config = {
      draft: { class: "bg-draft", text: "下書き" },
      in_progress: { class: "bg-in-progress", text: "作成中" },
      completed: { class: "bg-completed", text: "完成" },
      submitted: { class: "bg-submitted", text: "提出済み" },
      passed: { class: "bg-passed", text: "通過" },
      failed: { class: "bg-failed", text: "不合格" }
    }

    status = entry_sheet.status.to_sym
    config = status_config[status]
    return "" unless config

    badge_class = "badge rounded-pill #{config[:class]}"
    badge_class += " badge-sm" if size == :sm

    content_tag(:span, config[:text], class: badge_class)
  end

  # 空状態表示（アイコン＋メッセージ＋ボタン）
  def vault_empty_state(icon:, title:, message:, button_text: nil, button_path: nil)
    content_tag :div, class: "text-center py-5" do
      parts = [
        content_tag(:i, "", class: "fas fa-#{icon} fa-4x text-muted mb-4"),
        content_tag(:h3, title, class: "text-muted"),
        content_tag(:p, message, class: "text-muted mb-4")
      ]

      if button_text && button_path
        parts << link_to(button_path, class: "btn btn-primary") do
          safe_join([ content_tag(:i, "", class: "fas fa-plus me-2"), button_text ])
        end
      end

      safe_join(parts)
    end
  end

  # アクションボタン群（詳細・編集・削除）
  def vault_action_buttons(resource, show_path:, edit_path:, size: :sm, layout: :horizontal)
    content_tag :div, class: "d-flex gap-2" do
      detail_btn = link_to(show_path, class: "btn btn-#{size} #{layout == :horizontal ? 'flex-grow-1' : ''} btn-outline-primary") do
        safe_join([ content_tag(:i, "", class: "fas fa-eye me-1"), "詳細" ])
      end

      edit_btn = link_to(edit_path, class: "btn btn-#{size} btn-outline-secondary") do
        content_tag(:i, "", class: "fas fa-edit")
      end

      delete_btn = link_to(show_path, data: { turbo_method: :delete, turbo_confirm: "本当に削除しますか？" }, class: "btn btn-#{size} btn-outline-danger") do
        content_tag(:i, "", class: "fas fa-trash")
      end

      safe_join([ detail_btn, edit_btn, delete_btn ])
    end
  end

  # 日時フォーマット（アイコン付き）
  def vault_datetime_with_icon(datetime, icon:, label: nil)
    return "" unless datetime

    content_tag :small, class: "text-muted" do
      parts = [ content_tag(:i, "", class: "fas fa-#{icon} me-1") ]
      parts << "#{label}: " if label
      parts << datetime.strftime("%Y/%m/%d %H:%M")
      safe_join(parts)
    end
  end

  # カードヘッダー（グラデーション）
  def vault_card_header(title, icon: nil, &block)
    content_tag :div, class: "card-header bg-primary text-white" do
      if block_given?
        yield
      else
        content_tag :h5, class: "mb-0 fw-bold d-flex align-items-center" do
          parts = []
          parts << content_tag(:i, "", class: "fas fa-#{icon} me-2") if icon
          parts << title
          safe_join(parts)
        end
      end
    end
  end

  # カードヘッダー（ライト）
  def vault_card_header_light(title, icon: nil, &block)
    content_tag :div, class: "card-header" do
      if block_given?
        yield
      else
        content_tag :h5, class: "mb-0 fw-bold text-primary-dark d-flex align-items-center" do
          parts = []
          parts << content_tag(:i, "", class: "fas fa-#{icon} me-2 text-primary") if icon
          parts << title
          safe_join(parts)
        end
      end
    end
  end
end
