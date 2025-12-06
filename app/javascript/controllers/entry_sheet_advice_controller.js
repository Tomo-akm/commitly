import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { itemId: String }
  static targets = ["titleField", "contentField", "charLimitField", "errorContainer"]

  prepareSubmit(event) {
    this.clearError()

    const card = this.#findCard()
    if (!card) return this.#showError(event, '対応するフォームが見つかりません')

    const inputs = this.#getInputs(card)
    if (!inputs?.titleInput?.value.trim() || !inputs?.contentInput?.value.trim()) {
      return this.#showError(event, 'タイトルと内容を入力してください')
    }

    this.#populateHiddenFields(inputs)
  }

  clearError() {
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.innerHTML = ''
    }
  }

  // Private methods
  #findCard() {
    return document.querySelector(`.entry-sheet-item[data-item-id="${this.itemIdValue}"]`)
  }

  #getInputs(card) {
    return {
      titleInput: card.querySelector('textarea[name*="[title]"]'),
      contentInput: card.querySelector('textarea[name*="[content]"]'),
      charLimitInput: card.querySelector('input[name*="[char_limit]"]')
    }
  }

  #populateHiddenFields({ titleInput, contentInput, charLimitInput }) {
    this.titleFieldTarget.value = titleInput.value.trim()
    this.contentFieldTarget.value = contentInput.value.trim()
    this.charLimitFieldTarget.value = charLimitInput?.value ?? ''
  }

  #showError(event, message) {
    event.preventDefault()

    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.innerHTML = `
        <div class="alert alert-warning alert-dismissible fade show" role="alert">
          <i class="fas fa-exclamation-triangle me-2"></i>
          ${message}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      `
    }

    return false
  }
}
