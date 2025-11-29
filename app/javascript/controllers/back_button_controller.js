import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  goBack(event) {
    event.preventDefault()

    const container = document.getElementById("dm-container")

    if (container) {
      // Turbo Frame内の場合：クラスを削除してDM一覧を表示
      container.classList.remove("show-detail")
    } else {
      window.location.href = "/rooms"
    }
  }
}
