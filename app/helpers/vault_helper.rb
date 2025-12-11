# frozen_string_literal: true

module VaultHelper
  STATUS_CONFIG = {
    draft: { class: "bg-draft", text: "下書き" },
    in_progress: { class: "bg-in-progress", text: "作成中" },
    completed: { class: "bg-completed", text: "完成" },
    submitted: { class: "bg-submitted", text: "提出済み" },
    passed: { class: "bg-passed", text: "通過" },
    failed: { class: "bg-failed", text: "不合格" }
  }.freeze

  def entry_sheet_status_badge(entry_sheet, size: :md)
    config = STATUS_CONFIG[entry_sheet.status.to_sym]
    return "" unless config

    size_class = size == :sm ? " badge-sm" : ""
    content_tag(:span, config[:text], class: "badge rounded-pill #{config[:class]}#{size_class}")
  end

  def vault_empty_state(icon:, title:, message:, button_text: nil, button_path: nil)
    content_tag :div, class: "text-center py-5" do
      parts = [
        content_tag(:i, "", class: "fas fa-#{icon} fa-3x text-muted mb-4"),
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

  def vault_action_buttons(resource, show_path:, edit_path:, size: :sm, layout: :horizontal)
    content_tag :div, class: "d-flex gap-2" do
      safe_join([
        detail_button(show_path, size, layout),
        edit_button(edit_path, size),
        delete_button(show_path, size)
      ])
    end
  end

  def vault_datetime_with_icon(datetime, icon:, label: nil)
    return "" unless datetime

    content_tag :small, class: "text-muted" do
      parts = [ content_tag(:i, "", class: "fas fa-#{icon} me-1") ]
      parts << "#{label}: " if label
      parts << datetime.strftime("%Y/%m/%d %H:%M")
      safe_join(parts)
    end
  end

  def vault_card_header(title, icon: nil, style: :default, &block)
    header_class = case style
                   when :light then "card-header vault-light"
                   when :warning then "card-header vault-warning"
                   when :success then "card-header vault-success"
                   else "card-header vault"
                   end

    content_tag :div, class: header_class do
      block_given? ? yield : render_card_title(title, icon)
    end
  end

  def vault_card_header_light(title, icon: nil, &block)
    vault_card_header(title, icon: icon, style: :light, &block)
  end

  def vault_card_header_warning(title, icon: nil, &block)
    vault_card_header(title, icon: icon, style: :warning, &block)
  end

  def vault_card_header_success(title, icon: nil, &block)
    vault_card_header(title, icon: icon, style: :success, &block)
  end

  private

  def render_card_title(title, icon)
    content_tag :h5, class: "mb-0" do
      parts = []
      parts << content_tag(:i, "", class: "fas fa-#{icon}") if icon
      parts << title
      safe_join(parts)
    end
  end

  def action_button(text, path)
    link_to(path, class: "btn btn-primary") do
      safe_join([ content_tag(:i, "", class: "fas fa-plus me-2"), text ])
    end
  end

  def detail_button(path, size, layout)
    flex_class = layout == :horizontal ? " flex-grow-1" : ""
    link_to(path, class: "btn btn-#{size}#{flex_class} btn-outline-primary") do
      safe_join([ content_tag(:i, "", class: "fas fa-eye me-1"), "詳細" ])
    end
  end

  def edit_button(path, size)
    link_to(path, class: "btn btn-#{size} btn-outline-secondary") do
      content_tag(:i, "", class: "fas fa-edit")
    end
  end

  def delete_button(path, size)
    link_to(path, data: { turbo_method: :delete, turbo_confirm: "本当に削除しますか？" },
                  class: "btn btn-#{size} btn-outline-danger") do
      content_tag(:i, "", class: "fas fa-trash")
    end
  end
end
