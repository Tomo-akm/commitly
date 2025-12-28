import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.observeNewMessages()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  observeNewMessages() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.addedNodes.length > 0) {
          this.scrollToBottom()
        }
      })
    })

    this.observer.observe(this.element, {
      childList: true,
      subtree: true
    })
  }
}
