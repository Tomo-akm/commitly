import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidePanel", "divider"]

  connect() {
    this.panelOpen = false
    this.sidePanelWidth = 600
  }

  disconnect() {
    // リサイズ中の場合はクリーンアップ
    if (this.isResizing) {
      this.stopResize()
    }
    // パネルが開いている場合はbodyスタイルをリセット
    if (this.panelOpen) {
      this.hidePanel()
    }
  }

  openPanel(event) {
    const itemId = event.currentTarget.dataset.itemId
    this.switchPanel(`advice-panel-${itemId}`)
    if (!this.panelOpen) this.showPanel()
  }

  closePanel() {
    this.hidePanel()
  }

  switchPanel(panelId) {
    this.element.querySelectorAll('.side-panel-content').forEach(panel => {
      panel.style.display = panel.dataset.panelId === panelId ? 'block' : 'none'
    })
  }

  showPanel() {
    this.panelOpen = true
    this.updatePanelWidth(this.sidePanelWidth)
    this.sidePanelTarget.style.display = 'block'
    this.dividerTarget.style.display = 'block'
  }

  hidePanel() {
    this.panelOpen = false
    document.body.style.marginRight = '0'
    this.sidePanelTarget.style.display = 'none'
    this.dividerTarget.style.display = 'none'
  }

  startResize(event) {
    event.preventDefault()
    this.isResizing = true
    this.startX = event.clientX
    this.startWidth = this.sidePanelWidth

    this.resizeHandler = this.resize.bind(this)
    this.stopResizeHandler = this.stopResize.bind(this)

    document.addEventListener("mousemove", this.resizeHandler)
    document.addEventListener("mouseup", this.stopResizeHandler)
    document.body.style.cursor = "ew-resize"
    document.body.style.userSelect = "none"
  }

  resize(event) {
    if (!this.isResizing) return

    const maxWidth = window.innerWidth - 200
    const proposedWidth = this.startWidth + (this.startX - event.clientX)
    const newWidth = Math.max(400, Math.min(maxWidth, proposedWidth))

    this.sidePanelWidth = newWidth
    this.updatePanelWidth(newWidth)
  }

  stopResize() {
    if (!this.isResizing) return

    this.isResizing = false
    document.removeEventListener("mousemove", this.resizeHandler)
    document.removeEventListener("mouseup", this.stopResizeHandler)
    this.resizeHandler = null
    this.stopResizeHandler = null
    document.body.style.cursor = ""
    document.body.style.userSelect = ""
  }

  updatePanelWidth(width) {
    document.body.style.marginRight = `${width}px`
    this.sidePanelTarget.style.width = `${width}px`
    this.dividerTarget.style.right = `${width}px`
  }
}
