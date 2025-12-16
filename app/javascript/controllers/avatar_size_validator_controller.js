import { Controller } from '@hotwired/stimulus';

// アバター画像のファイルサイズバリデーション（5MB制限）
export default class extends Controller {
  static targets = ['input', 'error', 'submit'];

  connect() {
    this.maxSize = 5 * 1024 * 1024; // 5MB
  }

  validate(event) {
    const file = event.target.files[0];

    if (file && file.size > this.maxSize) {
      this.showError();
      event.target.value = ''; // ファイル選択をクリア
    } else {
      this.clearError();
    }
  }

  showError() {
    this.errorTarget.textContent = 'ファイルサイズは5MB未満にしてください';
    this.errorTarget.style.display = 'block';
  }

  clearError() {
    this.errorTarget.style.display = 'none';
  }
}
