import { Controller } from "@hotwired/stimulus"

// 返信の段階的表示を管理するコントローラー
// 20件ずつ表示し、全件表示後に「返信を非表示」ボタンを表示
// 一度全件表示したら、次回以降は一気に全件表示
export default class extends Controller {
  static targets = ["item", "initialShowMore", "showMore", "hideAll"]
  static values = { perPage: { type: Number, default: 20 } }

  connect() {
    this.currentCount = 0
    this.totalCount = this.itemTargets.length
    this.hasShownAll = false // 一度全件表示したかどうか
    this.hideAllItems()
    this.updateButtons()
  }

  // 全アイテムを非表示
  hideAllItems() {
    this.itemTargets.forEach(item => item.classList.add("d-none"))
  }

  // 全アイテムを表示
  showAllItems() {
    this.itemTargets.forEach(item => item.classList.remove("d-none"))
    this.currentCount = this.totalCount
  }

  // 次の20件を表示（または全件表示済みなら一気に全件）
  showMore() {
    if (this.hasShownAll) {
      // 一度全件表示したことがあれば、一気に全件表示
      this.showAllItems()
    } else {
      // 20件ずつ表示
      const start = this.currentCount
      const end = Math.min(start + this.perPageValue, this.totalCount)

      for (let i = start; i < end; i++) {
        this.itemTargets[i].classList.remove("d-none")
      }

      this.currentCount = end

      // 全件表示したらフラグを立てる
      if (this.currentCount >= this.totalCount) {
        this.hasShownAll = true
      }
    }

    this.updateButtons()
  }

  // 全て非表示（状態はリセットしない）
  hideAll() {
    this.hideAllItems()
    this.currentCount = 0
    this.updateButtons()
  }

  // ボタンの表示状態を更新
  updateButtons() {
    const noneShown = this.currentCount === 0
    const allShown = this.currentCount >= this.totalCount
    const partiallyShown = this.currentCount > 0 && !allShown

    // 「○件の返信」ボタン（投稿内）: 初期状態のみ表示
    if (this.hasInitialShowMoreTarget) {
      this.initialShowMoreTarget.classList.toggle("d-none", !noneShown)
    }

    // 「他の返信を表示」ボタン（コンテナ内）: 部分表示時に表示
    if (this.hasShowMoreTarget) {
      this.showMoreTarget.classList.toggle("d-none", !partiallyShown)
    }

    // 「返信を非表示」ボタン: 全件表示時に表示
    if (this.hasHideAllTarget) {
      this.hideAllTarget.classList.toggle("d-none", !allShown)
    }
  }
}
