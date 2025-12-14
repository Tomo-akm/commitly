import { Controller } from "@hotwired/stimulus"

// 本文中の #タグ とURLをハイライトし、検出されたタグ一覧を表示するコントローラー
export default class extends Controller {
  static targets = [ "textarea", "preview", "tagList" ]

  connect() {
    this.element.classList.add("text-input--enhanced")
    this.update()
  }

  disconnect() {
    this.element.classList.remove("text-input--enhanced")
  }

  update() {
    const text = this.textareaTarget.value || ""
    const tags = this.extractHashtags(text)
    this.renderPreview(text)
    this.renderTags(tags)
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

  renderTags(tags) {
    if (!this.hasTagListTarget) return

    this.tagListTarget.innerHTML = ""

    tags.forEach((name) => {
      const chip = document.createElement("span")
      chip.className = "hashtag-chip"
      chip.textContent = name
      this.tagListTarget.appendChild(chip)
    })

    this.tagListTarget.dataset.state = tags.length > 0 ? "has-tags" : "empty"
  }

  extractHashtags(text) {
    const seen = new Set()
    const tags = []

    for (const match of text.match(this.hashtagPattern) || []) {
      const tag = match.trim().replace(/^#/, "")
      if (seen.has(tag)) continue
      seen.add(tag)
      tags.push(tag)
    }

    return tags
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
    // Exclude common trailing punctuation from URL match
    return /(https?:\/\/[^\s<>"'`.,!?;:)\]\}]+[^\s<>"'`.,!?;:)\]\}])/g
  }
}
