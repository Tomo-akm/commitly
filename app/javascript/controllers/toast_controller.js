import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

/**
 * トースト通知を制御するStimulusコントローラー
 * - Bootstrap Toast を初期化して表示
 * - 右からスライドイン、右にスライドアウト
 * - 5秒後に自動的に非表示
 */
export default class extends Controller {
  connect() {
    const toast = new Toast(this.element, {
      autohide: true,
      delay: 5000
    })

    // 非表示開始時にアニメーションクラスを追加
    this.element.addEventListener('hide.bs.toast', () => {
      this.element.classList.add('hiding')
    })

    // 非表示後に要素を削除
    this.element.addEventListener('hidden.bs.toast', () => {
      this.element.remove()
    })

    toast.show()
  }
}
