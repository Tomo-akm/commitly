import { Controller } from "@hotwired/stimulus"

// テキストエリアの高さを自動調整するコントローラー
export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    // 一旦高さをリセットして正確なscrollHeightを取得
    this.element.style.height = 'auto'
    // コンテンツに合わせて高さを調整
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}