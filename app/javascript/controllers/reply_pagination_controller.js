import { Controller } from "@hotwired/stimulus"

// 返信の段階的表示を管理するコントローラー
// 20件ずつ表示し、全件表示後に「返信を非表示」ボタンを表示
export default class extends Controller {
  static targets = ["item", "showMore", "hideAll"]
  static values = { perPage: { type: Number, default: 20 } }

  connect() {
    this.currentCount = 0
    this.totalCount = this.itemTargets.length
    this.hideAllItems()
    this.updateButtons()
  }

  // 全アイテムを非表示
  hideAllItems() {
    this.itemTargets.forEach(item => item.classList.add("d-none"))
  }

  // 次の20件を表示
  showMore() {
    const start = this.currentCount
    const end = Math.min(start + this.perPageValue, this.totalCount)

    for (let i = start; i < end; i++) {
      this.itemTargets[i].classList.remove("d-none")
    }

    this.currentCount = end
    this.updateButtons()
  }

  // 全て非表示にしてリセット
  hideAll() {
    this.hideAllItems()
    this.currentCount = 0
    this.updateButtons()
  }

  // ボタンの表示状態を更新
  updateButtons() {
    const allShown = this.currentCount >= this.totalCount
    const noneShown = this.currentCount === 0

    // 「もっと返信を表示」ボタン: 未表示のアイテムがある時
    if (this.hasShowMoreTarget) {
      this.showMoreTarget.classList.toggle("d-none", allShown)
      // 残り件数を更新
      const remaining = this.totalCount - this.currentCount
      const label = noneShown
        ? `${this.totalCount}件の返信`
        : `さらに${remaining}件の返信を表示`
      this.showMoreTarget.textContent = label
    }

    // 「返信を非表示」ボタン: 全件表示された時
    if (this.hasHideAllTarget) {
      this.hideAllTarget.classList.toggle("d-none", !allShown)
    }
  }
}
