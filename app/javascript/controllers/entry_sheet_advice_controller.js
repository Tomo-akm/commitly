import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { itemId: String }
  static targets = ["titleField", "contentField", "charLimitField"]

  prepareSubmit(event) {
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

  handleError(event, message) {
    event.preventDefault()
    alert(message)
    return false
  }
}
