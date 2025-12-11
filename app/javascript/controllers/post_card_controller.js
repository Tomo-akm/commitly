import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="post-card"
export default class extends Controller {
  navigate(event) {
    // インタラクティブな要素やバッジのクリックは無視
    const target = event.target
    const isInteractiveElement = target.closest([
      'a',                      // リンク（ユーザー名、タグなど）
      'button',                 // ボタン（Star、リプライなど）
      'form',                   // フォーム
      '[data-bs-toggle]',       // モーダルトリガー
      '.job-hunting-badge',     // 就活バッジ（将来的にクリッカブルにする可能性）
      '.dropdown',              // ドロップダウンメニュー全体
      '.dropdown-menu',         // ドロップダウンメニュー本体
    ].join(', '))

    if (!isInteractiveElement) {
      const url = this.element.dataset.postUrl
      if (url) {
        window.location.href = url
      }
    }
  }
}
