import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "image", "placeholder"]

  triggerFileInput() {
    this.inputTarget.click()
  }

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasImageTarget) {
        this.imageTarget.src = e.target.result
      } else if (this.hasPlaceholderTarget) {
        const img = document.createElement("img")
        img.src = e.target.result
        img.className = "avatar-upload__image"
        img.dataset.avatarPreviewTarget = "image"
        this.placeholderTarget.replaceWith(img)
      }
    }
    reader.readAsDataURL(file)
  }
}
