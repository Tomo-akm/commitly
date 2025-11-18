import { Controller } from "@hotwired/stimulus"

// ネストフォーム（動的項目追加・削除）コントローラー
export default class extends Controller {
  static targets = ["container", "item", "destroyField"]

  // 新しい項目を追加
  addItem(event) {
    event.preventDefault()

    const container = this.containerTarget
    const items = this.itemTargets

    // テンプレートとして最後の項目を使用
    const templateItem = items[items.length - 1]

    if (!templateItem) {
      console.error('No template item found')
      return
    }

    // 最後の項目をクローン
    const newItem = templateItem.cloneNode(true)

    // インデックスを更新（表示中の項目数を基準）
    const newIndex = items.filter(item => item.style.display !== 'none').length
    this.updateItemIndex(newItem, newIndex)

    // フォームの値をクリア
    this.clearFormValues(newItem)

    // 表示してコンテナに追加
    newItem.style.display = ''
    container.appendChild(newItem)

    // 項目番号を更新
    this.updateItemNumbers()
  }

  // 項目を削除（または非表示に）
  removeItem(event) {
    event.preventDefault()

    const item = event.target.closest('[data-nested-form-target="item"]')
    if (!item) return

    const destroyField = item.querySelector('[data-nested-form-target="destroyField"]')

    if (destroyField) {
      // 既存レコード: _destroyフラグを立てて非表示に
      destroyField.value = '1'
      item.style.display = 'none'
    } else {
      // 新規項目: DOMから削除
      item.remove()
    }

    // 項目番号を更新
    this.updateItemNumbers()
  }

  // フォームフィールドのインデックスを更新
  updateItemIndex(item, newIndex) {
    // input/textarea/selectのname/id属性を更新
    const inputs = item.querySelectorAll('input, textarea, select')
    inputs.forEach(input => {
      if (input.name) {
        input.name = input.name.replace(/\[\d+]/, `[${newIndex}]`)
      }
      if (input.id) {
        input.id = input.id.replace(/_\d+_/, `_${newIndex}_`)
      }
    })

    // labelのfor属性を更新
    const labels = item.querySelectorAll('label')
    labels.forEach(label => {
      if (label.htmlFor) {
        label.htmlFor = label.htmlFor.replace(/_\d+_/, `_${newIndex}_`)
      }
    })
  }

  // フォームの値をクリア（新規項目として初期化）
  clearFormValues(item) {
    // 表示用フィールドをクリア
    const inputs = item.querySelectorAll('input:not([type="hidden"]), textarea, select')
    inputs.forEach(input => {
      if (input.type === 'checkbox' || input.type === 'radio') {
        input.checked = false
      } else {
        input.value = ''
      }
    })

    // _destroyフィールドをクリア
    const destroyField = item.querySelector('[data-nested-form-target="destroyField"]')
    if (destroyField) {
      destroyField.value = ''
    }

    // idフィールドを削除（新規レコードとして扱うため）
    const idField = item.querySelector('input[name*="[id]"]')
    if (idField) {
      idField.remove()
    }
  }

  // 項目番号を更新（表示中の項目のみ）
  updateItemNumbers() {
    const visibleItems = this.itemTargets.filter(item => item.style.display !== 'none')
    visibleItems.forEach((item, index) => {
      const header = item.querySelector('h6')
      if (header) {
        // テキストのみ更新（クラスや子要素を保持）
        const currentText = header.textContent.trim()
        if (currentText.startsWith('項目')) {
          header.textContent = `項目 ${index + 1}`
        }
      }
    })
  }
}
