import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidePanel", "divider", "left"]

  connect() {
    this.isDragging = false
    this.activePointerId = null
  }

  disconnect() {
    this.#cleanup()
  }

  openPanel(event) {
    document.body.classList.add("side-panel-open")
    this.element.classList.add("panel-open")

    const itemId = event?.currentTarget?.dataset?.itemId
    if (itemId) this.#switchPanel(`advice-panel-${itemId}`)

    if (this.#isMobile()) {
      this.sidePanelTarget.style.display = "block"
    } else {
      this.#syncLayout()
    }
  }

  closePanel() {
    document.body.classList.remove("side-panel-open")
    this.element.classList.remove("panel-open")

    if (this.#isMobile()) {
      this.sidePanelTarget.style.display = "none"
    } else {
      this.dividerTarget.style.right = ""
      this.leftTarget.style.marginRight = ""
    }
  }

  startResize(event) {
    if (this.#isMobile()) return

    this.isDragging = true
    this.activePointerId = event.pointerId
    this.dividerTarget.setPointerCapture?.(event.pointerId)
    window.addEventListener("pointermove", this.#resizePanel)
    window.addEventListener("pointerup", this.#stopResize)
    window.addEventListener("pointercancel", this.#stopResize)
    event.preventDefault()
  }

  #resizePanel = (event) => {
    if (!this.isDragging) return
    if (this.activePointerId !== null && event.pointerId !== this.activePointerId) return

    if (typeof event.clientX !== "number") return

    const newWidth = window.innerWidth - event.clientX
    const width = Math.max(300, Math.min(600, newWidth))
    this.sidePanelTarget.style.width = `${width}px`
    this.#syncLayout()
  }

  #stopResize = (event) => {
    this.isDragging = false
    if (this.activePointerId !== null) {
      this.dividerTarget.releasePointerCapture?.(this.activePointerId)
    }
    this.activePointerId = null
    window.removeEventListener("pointermove", this.#resizePanel)
    window.removeEventListener("pointerup", this.#stopResize)
    window.removeEventListener("pointercancel", this.#stopResize)
  }

  #switchPanel(panelId) {
    this.element.querySelectorAll(".side-panel-content").forEach(panel => {
      panel.style.display = (panel.dataset.panelId === panelId) ? "block" : "none"
    })
  }

  #syncLayout() {
    const panelWidth = parseFloat(this.sidePanelTarget.style.width) || this.sidePanelTarget.offsetWidth
    this.dividerTarget.style.right = `${panelWidth}px`
    this.leftTarget.style.marginRight = `${panelWidth}px`
  }

  #isMobile() {
    return window.innerWidth <= 767.98
  }

  #cleanup() {
    if (this.isDragging) this.#stopResize()
    document.body.classList.remove("side-panel-open")
    this.element.classList.remove("panel-open")
  }
}
