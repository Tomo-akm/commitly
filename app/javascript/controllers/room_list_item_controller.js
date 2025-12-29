import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    roomId: Number,
  }

  connect() {
    this.element.setAttribute("data-turbo-frame", "room_detail")
  }

  click() {
    const isDesktop = window.matchMedia("(min-width: 768px)").matches
    this.clearUnreadBadge()
    this.updateTotalUnreadCount()

    if (!isDesktop) {
      const container = document.getElementById("dm-container")
      if (container) {
        container.classList.add("show-detail")
      }
    }
  }

  clearUnreadBadge() {
    const roomElement = document.getElementById(`room_${this.roomIdValue}`)
    if (roomElement) {
      const badge = roomElement.querySelector(".badge.bg-danger")
      if (badge) {
        badge.parentElement.remove()
      }

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
