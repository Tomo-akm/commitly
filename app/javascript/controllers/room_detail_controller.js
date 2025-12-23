import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="room-detail"
export default class extends Controller {
  static values = {
    roomId: Number,
  }

  connect() {
    this.clearRoomUnreadBadge()
    this.updateTotalUnreadCount()
  }

  goBack(event) {
    event.preventDefault()

    // モバイル：コンテナから.show-detailクラスを削除してDM一覧を表示
    const container = document.getElementById("dm-container")

    if (container) {
      // Turbo Frame内の場合：クラスを削除してDM一覧を表示
      container.classList.remove("show-detail")
    } else {
      // Turbo Frame外（直接アクセス）の場合：rooms_pathに遷移
      window.location.href = "/rooms"
    }
  }

  clearRoomUnreadBadge() {
    const roomElement = document.getElementById(`room_${this.roomIdValue}`)
    if (roomElement) {
      const badge = roomElement.querySelector(".badge.bg-danger")
      if (badge) {
        badge.parentElement.remove()
      }
      // テキストも通常の太さに変更
      const nameElement = roomElement.querySelector("h6")
      if (nameElement) {
        nameElement.classList.remove("fw-bold")
        nameElement.classList.add("fw-normal")
      }
      const messagePreview = roomElement.querySelector("p.text-muted")
      if (messagePreview) {
        messagePreview.classList.remove("fw-semibold")
      }
    }
  }

  updateTotalUnreadCount() {
    const badges = document.querySelectorAll(
      ".list-group-item .badge.bg-danger"
    )
    const total = Array.from(badges).reduce((sum, badge) => {
      return sum + parseInt(badge.textContent)
    }, 0)

    const totalBadgeContainer = document.getElementById("total-unread-badge")
    if (totalBadgeContainer) {
      if (total > 0) {
        totalBadgeContainer.innerHTML = `<span class="badge bg-danger rounded-pill ms-1">${total}</span>`
      } else {
        totalBadgeContainer.innerHTML = ""
      }
    }
  }
}
