import { Controller } from "@hotwired/stimulus"

// 無限スクロールのローディング最小遅延コントローラー
// スケルトンを最低限の時間表示してユーザー体験を向上
export default class extends Controller {
  static values = {
    minDelay: { type: Number, default: 500 }
  }

  connect() {
    this.startTime = null
    // 保持されたバインド済みハンドラを使うことで、disconnect 時に確実に解除できるようにする
    if (!this._handleStart) {
      this._handleStart = this.start.bind(this)
    }
    if (!this._handleBeforeRender) {
      this._handleBeforeRender = this.beforeRender.bind(this)
    }
    this.element.addEventListener("turbo:before-fetch-request", this._handleStart)
    this.element.addEventListener("turbo:before-frame-render", this._handleBeforeRender)
  }

  disconnect() {
    if (this._handleStart) {
      this.element.removeEventListener("turbo:before-fetch-request", this._handleStart)
    }
    if (this._handleBeforeRender) {
      this.element.removeEventListener("turbo:before-frame-render", this._handleBeforeRender)
    }
  }

  start() {
    this.startTime = performance.now()
  }

  beforeRender(event) {
    if (this.startTime === null) return

    const elapsed = performance.now() - this.startTime
    const remaining = this.minDelayValue - elapsed

    if (remaining > 0) {
      event.preventDefault()
      const resume = event.detail.resume
      setTimeout(() => {
        this.startTime = null
        resume()
      }, remaining)
    } else {
      this.startTime = null
    }
  }
}
