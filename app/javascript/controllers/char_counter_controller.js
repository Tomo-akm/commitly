import { Controller } from "@hotwired/stimulus"

// 文字数カウンターコントローラー
export default class extends Controller {
  static targets = ["count", "limit", "textarea"]
  static values = { limit: { type: Number, default: 0 } }

  connect() {
    this.update()
  }

  // テキストエリア入力時に呼ばれる
  update() {
    if (!this.hasTextareaTarget) return

    const currentCount = this.textareaTarget.value.length
    this.countTarget.textContent = currentCount

    // 制限超過時の警告表示
    const isOverLimit = this.limitValue > 0 && currentCount > this.limitValue
    this.element.classList.toggle('over-limit', isOverLimit)
    this.countTarget.classList.toggle('text-danger', isOverLimit)
    this.countTarget.classList.toggle('fw-bold', isOverLimit)
  }

  // 文字数制限フィールド変更時に呼ばれる
  updateLimit(event) {
    const newLimit = parseInt(event.target.value) || 0
    this.limitValue = newLimit

    if (this.hasLimitTarget) {
      this.limitTarget.textContent = newLimit > 0 ? newLimit : "制限なし"
    }

    this.update()
  }
}