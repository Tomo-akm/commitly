import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "input", "list"]
  static values = {
    url: String,
    mode: { type: String, default: "hashtag" }  // "hashtag" or "simple"
  }

  connect() {
    this.activeRange = null
    this.selectedIndex = -1
  }

  // textarea または input を取得
  get fieldTarget() {
    return this.hasInputTarget ? this.inputTarget : this.textareaTarget
  }

  onInput() {
    const match = this.modeValue === "simple" ? this.currentSimpleInput() : this.currentHashtag()
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

    const field = this.fieldTarget
    const { start, end } = this.activeRange

    if (this.modeValue === "simple") {
      // simpleモード: フィールド全体を置き換え（#なし）
      field.value = tag
      field.focus()
    } else {
      // hashtagモード: ハッシュタグとして挿入（#あり）
      const before = field.value.slice(0, start)
      const after  = field.value.slice(end)

      field.value = `${before}#${tag} ${after}`
      field.focus()

      // カーソルを補完後の末尾へ
      const cursor = before.length + tag.length + 2
      field.setSelectionRange(cursor, cursor)
    }

    this.hide()

    // text-highlighter を即時更新
    field.dispatchEvent(new Event("input", { bubbles: true }))
  }

  // simpleモード用: フィールド全体の値を検索クエリにする
  currentSimpleInput() {
    const field = this.fieldTarget
    const query = field.value.trim()

    if (query.length === 0) return null

    return {
      query,
      range: { start: 0, end: field.value.length }
    }
  }

  // hashtagモード用: 直前のハッシュタグを検出
  currentHashtag() {
    const field = this.fieldTarget
    const pos = field.selectionStart
    const text = field.value.slice(0, pos)

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
      const name = typeof tag === "string" ? tag : tag.name
      const count = typeof tag === "string" ? null : tag.posts_count
      if (!name) return

      const li = document.createElement("li")
      li.dataset.tag = name
      li.className = "tag-autocomplete__item d-flex justify-content-between align-items-center"

      const label = document.createElement("span")
      // simpleモードでは#を付けない
      label.textContent = this.modeValue === "simple" ? name : `#${name}`
      li.appendChild(label)

      if (typeof count === "number") {
        const badge = document.createElement("span")
        badge.className = "badge bg-light text-dark"
        // simpleモードでは「件」を追加
        badge.textContent = this.modeValue === "simple" ? `${count}件` : count
        li.appendChild(badge)
      }

      li.addEventListener("mousedown", e => {
        e.preventDefault() // textarea blur 防止
        this.select(e)
      })
      this.listTarget.appendChild(li)
    })

    this.listTarget.hidden = false
  }

  // フォーカスが外れたときにリストを非表示（simpleモード用）
  onBlur() {
    setTimeout(() => this.hide(), 200)
  }

  hide() {
    this.listTarget.hidden = true
    this.listTarget.innerHTML = ""
    this.activeRange = null
    this.selectedIndex = -1
  }
}
