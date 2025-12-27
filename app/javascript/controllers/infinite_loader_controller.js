import { Controller } from "@hotwired/stimulus"

// 無限スクロールのローディング最小遅延コントローラー
// スケルトンを最低限の時間表示してユーザー体験を向上
export default class extends Controller {
  static values = {
    minDelay: { type: Number, default: 700 }
  }

  constructor(...args) {
    super(...args)
    // ハンドラはインスタンス生成時に一度だけバインドして再利用する
    this._handleStart = this.start.bind(this)
    this._handleBeforeRender = this.beforeRender.bind(this)
  }

  connect() {
    // 複数フレームの同時読み込みに対応するため、フレームIDごとに開始時間を追跡
    this.startTimes = new Map()

    this.element.addEventListener("turbo:before-fetch-request", this._handleStart)
    this.element.addEventListener("turbo:before-frame-render", this._handleBeforeRender)
  }

  disconnect() {
    // Mapをクリア
    if (this.startTimes) {
      this.startTimes.clear()
    }

    if (this._handleStart) {
      this.element.removeEventListener("turbo:before-fetch-request", this._handleStart)
    }
    if (this._handleBeforeRender) {
      this.element.removeEventListener("turbo:before-frame-render", this._handleBeforeRender)
    }
  }

  start(event) {
    const frameId = event.target.id
    if (frameId) {
      this.startTimes.set(frameId, performance.now())
    }
  }

  beforeRender(event) {
    const frameId = event.target.id
    const startTime = this.startTimes.get(frameId)

    if (!startTime) return

    const elapsed = performance.now() - startTime
    const remaining = this.minDelayValue - elapsed

    if (remaining > 0) {
      event.preventDefault()
      const resume = event.detail.resume
      setTimeout(() => {
        this.startTimes.delete(frameId)
        resume()
      }, remaining)
    } else {
      this.startTimes.delete(frameId)
    }
  }
}
