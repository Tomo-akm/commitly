import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidePanel", "divider", "left"]

  connect() {
    this.isDragging = false
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
    }
  }

  closePanel() {
    document.body.classList.remove("side-panel-open")
    this.element.classList.remove("panel-open")

    if (this.#isMobile()) {
      this.sidePanelTarget.style.display = "none"
    }
  }

  startResize(event) {
    if (this.#isMobile()) return

    this.isDragging = true
    document.addEventListener("mousemove", this.#resizePanel)
    document.addEventListener("mouseup", this.#stopResize)
    event.preventDefault()
  }

  #resizePanel = (event) => {
    if (!this.isDragging) return

    const newWidth = window.innerWidth - event.clientX
    const width = Math.max(300, Math.min(600, newWidth))
    this.sidePanelTarget.style.width = `${width}px`
  }

  #stopResize = () => {
    this.isDragging = false
    document.removeEventListener("mousemove", this.#resizePanel)
    document.removeEventListener("mouseup", this.#stopResize)
  }

  #switchPanel(panelId) {
    this.element.querySelectorAll(".side-panel-content").forEach(panel => {
      panel.style.display = (panel.dataset.panelId === panelId) ? "block" : "none"
    })
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

