import { Controller } from "@hotwired/stimulus"

// テンプレート読み込みコントローラー
export default class extends Controller {
  // テンプレートを読み込んでフォームに反映
  loadTemplate(event) {
    event.preventDefault()

    const card = event.target.closest('[data-nested-form-target="item"]')
    if (!card) return

    const select = card.querySelector('[data-template-select="true"]')
    if (!select || !select.value) {
      alert('テンプレートを選択してください')
      return
    }

    const selectedOption = select.options[select.selectedIndex]
    const title = selectedOption.dataset.title
    const content = selectedOption.dataset.content

    // フォームに値を設定
    const titleTextarea = card.querySelector('textarea[name*="[title]"]')
    const contentTextarea = card.querySelector('textarea[name*="[content]"]')
    const templateIdField = card.querySelector('input[name*="[entry_sheet_item_template_id]"]')

    if (titleTextarea) {
      titleTextarea.value = title
      titleTextarea.dispatchEvent(new Event('input')) // autosizeトリガー
    }

    if (contentTextarea) {
      contentTextarea.value = content
      contentTextarea.dispatchEvent(new Event('input')) // 文字数カウンター + autosizeトリガー
    }

    if (templateIdField) {
      templateIdField.value = select.value
    }

    // 成功メッセージ表示
    this.showSuccessMessage(card)
  }

  // 成功メッセージバッジを表示（3秒後に自動削除）
  showSuccessMessage(card) {
    const badge = document.createElement('span')
    badge.className = 'badge bg-success ms-2'
    badge.innerHTML = '<i class="fas fa-check me-1"></i>テンプレート読み込み完了'

    const header = card.querySelector('h6')
    if (header) {
      // 既存のバッジがあれば削除
      const existingBadge = header.querySelector('.badge')
      if (existingBadge) existingBadge.remove()

      header.appendChild(badge)
      setTimeout(() => badge.remove(), 3000)
    }
  }
}