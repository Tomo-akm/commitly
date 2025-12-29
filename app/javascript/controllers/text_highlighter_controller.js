import { Controller } from "@hotwired/stimulus"

// 本文中の #タグ とURLをハイライトするコントローラー
export default class extends Controller {
  static targets = [ "textarea", "preview" ]

  connect() {
    this.element.classList.add("text-input--enhanced")
    this.update()
  }

  disconnect() {
    this.element.classList.remove("text-input--enhanced")
  }

  update() {
    const text = this.textareaTarget.value || ""
    this.renderPreview(text)
  }

  renderPreview(text) {
    if (!this.hasPreviewTarget) return

    const trimmed = text.trim()
    if (trimmed.length === 0) {
      // textareaのplaceholderはtransparentにしているため、
      // 空のときはpreview側でplaceholderを表示する
      this.previewTarget.innerText = this.placeholderText
      this.previewTarget.classList.add("is-placeholder")
      return
    }

    this.previewTarget.classList.remove("is-placeholder")
    const escaped = this.escapeHtml(text)

    // ハッシュタグとURLをハイライト
    const highlighted = escaped
      // まずハッシュタグをハイライト（空白を保持）
      .replace(
        this.hashtagPattern,
        (_, space, tag) => `${space}<span class="hashtag-highlight">${tag}</span>`
      )
      // 次にURLをハイライト
      .replace(
        this.urlPattern,
        (url) => `<span class="url-highlight">${url}</span>`
      )

    this.previewTarget.innerHTML = highlighted
  }

  escapeHtml(unsafe) {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }

  get placeholderText() {
    return this.textareaTarget.placeholder || "#タグ を本文に入れるとタグになります"
  }

  get hashtagPattern() {
    // キャプチャグループ: (1)空白/行頭 (2)ハッシュタグ本体
    // \u3000 = 全角スペース
    return /(^|[\s\u3000])(#[\p{Letter}\p{Number}_]+)(?=[\s\u3000]|$)/gu
  }

  get urlPattern() {
    // TextHighlighterHelperと同じパターンを使用（末尾の句読点のみlookaheadで除外）
    return /(https?:\/\/[^\s<>"]+?)(?=[<>".,;!?)]*(?:\s|$))/g
  }
}
