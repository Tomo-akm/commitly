import { Controller } from "@hotwired/stimulus"

// 無限スクロールのローディング最小遅延コントローラー
// スケルトンを最低限の時間表示してユーザー体験を向上
export default class extends Controller {
  static values = {
    minDelay: { type: Number, default: 500 }
  }

  connect() {
    this.startTime = null
    this.element.addEventListener("turbo:before-fetch-request", this.start.bind(this))
    this.element.addEventListener("turbo:before-frame-render", this.beforeRender.bind(this))
  }

  start() {
    this.startTime = performance.now()
  }

  beforeRender(event) {
    if (!this.startTime) return

    const elapsed = performance.now() - this.startTime
    const remaining = this.minDelayValue - elapsed

    if (remaining > 0) {
      event.preventDefault()
      setTimeout(() => event.detail.resume(), remaining)
    }
  }
}
