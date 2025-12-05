import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { itemId: String }
  static targets = ["titleField", "contentField", "charLimitField"]

  prepareSubmit(event) {
    this.clearError()

    const card = this.findEntrySheetCard()
    if (!card) return this.handleError(event, '対応するフォームが見つかりません')

    const inputs = this.findInputFields(card)
    if (!inputs) return this.handleError(event, '入力値が取得できません')

    if (!this.validateInputs(inputs)) {
      return this.handleError(event, 'タイトルと内容を入力してください')
    }

    this.setHiddenFields(inputs)
  }

  findEntrySheetCard() {
    return document.querySelector(`.entry-sheet-item[data-item-id="${this.itemIdValue}"]`)
  }

  findInputFields(card) {
    const titleInput = card.querySelector('textarea[name*="[title]"]')
    const contentInput = card.querySelector('textarea[name*="[content]"]')
    const charLimitInput = card.querySelector('input[name*="[char_limit]"]')

    return (titleInput && contentInput) ? { titleInput, contentInput, charLimitInput } : null
  }

  validateInputs({ titleInput, contentInput }) {
    return titleInput.value.trim() && contentInput.value.trim()
  }

  setHiddenFields({ titleInput, contentInput, charLimitInput }) {
    this.titleFieldTarget.value = titleInput.value.trim()
    this.contentFieldTarget.value = contentInput.value.trim()
    this.charLimitFieldTarget.value = charLimitInput?.value || ''
  }

  clearError() {
    const errorContainer = document.getElementById(`advice_form_error_${this.itemIdValue}`)
    if (errorContainer) {
      errorContainer.innerHTML = ''
    }
  }

  handleError(event, message) {
    event.preventDefault()

    const errorContainer = document.getElementById(`advice_form_error_${this.itemIdValue}`)
    if (errorContainer) {
      errorContainer.innerHTML = `
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
