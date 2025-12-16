import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "list"]
  static values = { url: String }

  connect() {
    this.activeRange = null
    this.selectedIndex = -1
  }

  onInput() {
    const match = this.currentHashtag()
    if (!match) {
      this.hide()
      return
    }

    const { query, range } = match
    this.activeRange = range

    fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
      .then(r => r.json())
      .then(tags => {
        if (tags.length === 0) {
          this.hide()
          return
        }
        this.show(tags)
      })
      .catch(() => this.hide())
  }

  onKeyDown(event) {
    if (this.listTarget.hidden) return

    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectNext()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectPrevious()
        break
      case 'Enter':
        event.preventDefault()
        this.confirmSelection()
        break
      case 'Escape':
        event.preventDefault()
        this.hide()
        break
    }
  }

  selectNext() {
    const items = this.listTarget.querySelectorAll('.tag-autocomplete__item')
    if (items.length === 0) return

    this.selectedIndex = (this.selectedIndex + 1) % items.length
    this.updateSelection(items)
  }

  selectPrevious() {
    const items = this.listTarget.querySelectorAll('.tag-autocomplete__item')
    if (items.length === 0) return

    this.selectedIndex = this.selectedIndex <= 0 ? items.length - 1 : this.selectedIndex - 1
    this.updateSelection(items)
  }

  updateSelection(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('is-selected')
        item.scrollIntoView({ block: 'nearest' })
      } else {
        item.classList.remove('is-selected')
      }
    })
  }

  confirmSelection() {
    const items = this.listTarget.querySelectorAll('.tag-autocomplete__item')
    if (this.selectedIndex >= 0 && this.selectedIndex < items.length) {
      const selectedItem = items[this.selectedIndex]
      this.applyTag(selectedItem.dataset.tag)
    }
  }

  select(event) {
    const tag = event.currentTarget.dataset.tag
    if (!tag) return
    this.applyTag(tag)
  }

  applyTag(tag) {
    if (!tag || !this.activeRange) return

    const textarea = this.textareaTarget
    const { start, end } = this.activeRange

    const before = textarea.value.slice(0, start)
    const after  = textarea.value.slice(end)

    textarea.value = `${before}#${tag} ${after}`
    textarea.focus()

    // カーソルを補完後の末尾へ
    const cursor = before.length + tag.length + 2
    textarea.setSelectionRange(cursor, cursor)

    this.hide()

    // text-highlighter を即時更新
    textarea.dispatchEvent(new Event("input", { bubbles: true }))
  }

  currentHashtag() {
    const textarea = this.textareaTarget
    const pos = textarea.selectionStart
    const text = textarea.value.slice(0, pos)

    // 直前の #xxxx を検出
    const match = text.match(/(?:^|[\s\u3000])#([\p{Letter}\p{Number}_]*)$/u)
    if (!match) return null

    const query = match[1]
    const start = pos - query.length - 1
    const end = pos

    return { query, range: { start, end } }
  }

  show(tags) {
    this.listTarget.innerHTML = ""
    this.selectedIndex = -1

    tags.forEach(tag => {
      const li = document.createElement("li")
      li.textContent = `#${tag}`
      li.dataset.tag = tag
      li.className = "tag-autocomplete__item"
      li.addEventListener("mousedown", e => {
        e.preventDefault() // textarea blur 防止
        this.select(e)
      })
      this.listTarget.appendChild(li)
    })

    this.listTarget.hidden = false
  }

  hide() {
    this.listTarget.hidden = true
    this.listTarget.innerHTML = ""
    this.activeRange = null
    this.selectedIndex = -1
  }
}