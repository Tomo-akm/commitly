import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidePanel", "divider"]

  connect() {
    this.width = 600
  }

  disconnect() {
    this.#cleanup()
  }

  openPanel(event) {
    const itemId = event.currentTarget.dataset.itemId
    this.#switchPanel(`advice-panel-${itemId}`)
    this.#show()
  }

  closePanel() {
    this.#hide()
  }

  startResize(event) {
    event.preventDefault()
    this.resizing = { startX: event.clientX, startWidth: this.width }

    document.addEventListener("mousemove", this.#resize)
    document.addEventListener("mouseup", this.#stopResize)
    document.body.style.cursor = "ew-resize"
    document.body.style.userSelect = "none"
  }

  #resize = (event) => {
    if (!this.resizing) return

    const delta = this.resizing.startX - event.clientX
    const newWidth = Math.max(400, Math.min(window.innerWidth - 200, this.resizing.startWidth + delta))

    this.width = newWidth
    this.#updateWidth(newWidth)
  }

  #stopResize = () => {
    if (!this.resizing) return

    this.resizing = null
    document.removeEventListener("mousemove", this.#resize)
    document.removeEventListener("mouseup", this.#stopResize)
    document.body.style.cursor = ""
    document.body.style.userSelect = ""
  }

  #switchPanel(panelId) {
    this.element.querySelectorAll('.side-panel-content').forEach(panel => {
      panel.style.display = panel.dataset.panelId === panelId ? 'block' : 'none'
    })
  }

  #show() {
    this.#updateWidth(this.width)
    this.sidePanelTarget.style.display = 'block'
    this.dividerTarget.style.display = 'block'
  }

  #hide() {
    document.body.style.marginRight = '0'
    this.sidePanelTarget.style.display = 'none'
    this.dividerTarget.style.display = 'none'
  }

  #updateWidth(width) {
    document.body.style.marginRight = `${width}px`
    this.sidePanelTarget.style.width = `${width}px`
    this.dividerTarget.style.right = `${width}px`
  }

  #cleanup() {
    if (this.resizing) this.#stopResize()
    if (this.sidePanelTarget.style.display === 'block') this.#hide()
  }
}
