import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="room-detail"
export default class extends Controller {
  static values = {
    roomId: Number,
    otherUserId: Number,
  }

  connect() {
    this.clearRoomUnreadBadge()
    this.updateTotalUnreadCount()
    this.markAsRead()
    this.observeTurboStreams()
  }

  disconnect() {
    if (this.turboStreamHandler) {
      document.removeEventListener("turbo:before-stream-render", this.turboStreamHandler)
    }
  }

  observeTurboStreams() {
    this.turboStreamHandler = (event) => {
      const fallbackToTemplate = event.detail?.newStream || event.target
      const action = fallbackToTemplate?.getAttribute('action')
      const target = fallbackToTemplate?.getAttribute('target')

      if (action === 'append' && target === 'messages') {
        this.markAsRead()
        this.clearRoomUnreadBadge()
        this.updateTotalUnreadCount()
      }
    }

    document.addEventListener("turbo:before-stream-render", this.turboStreamHandler)
  }

  markAsRead() {
    if (!this.hasOtherUserIdValue) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrfToken) return

    fetch(`/rooms/${this.otherUserIdValue}/mark_as_read`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json'
      }
    })
      .then((response) => {
        if (!response.ok) {
          console.error(
            `Failed to mark room as read for user ${this.otherUserIdValue}: ${response.status} ${response.statusText}`
          )
        }
      })
      .catch((error) => {
        console.error(
          `Network error while marking room as read for user ${this.otherUserIdValue}:`,
          error
        )
      })
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

    const badgeTargets = [
      document.getElementById("total_unread_badge"),
      document.getElementById("left_unread_badge"),
    ].filter(Boolean)

    badgeTargets.forEach((container) => {
      if (total > 0) {
        container.innerHTML = `<span class="badge bg-danger rounded-pill ms-1">${total}</span>`
      } else {
        container.innerHTML = ""
      }
    })
  }
}
