import { Controller } from '@hotwired/stimulus';
import { Modal } from 'bootstrap';

// アバター拡大表示コントローラー
export default class extends Controller {
  static values = {
    avatarUrl: String,
  };

  openModal(event) {
    event.preventDefault();
    event.stopPropagation();

    const modalElement = document.getElementById('avatarModal');
    if (!modalElement) return;

    // モーダルの画像を更新
    const imageEl = modalElement.querySelector('#avatarModalImage');
    if (imageEl) {
      imageEl.src = this.avatarUrlValue;
    }

    // モーダルを開く
    const modal = Modal.getOrCreateInstance(modalElement);
    modal.show();
  }
}