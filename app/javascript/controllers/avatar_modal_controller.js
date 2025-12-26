import { Controller } from '@hotwired/stimulus';
import { Modal } from 'bootstrap';

// アバター拡大表示コントローラー
export default class extends Controller {
  static values = {
    avatarUrl: String,
    modalId: String,
  };

  openModal(event) {
    event.preventDefault();
    event.stopPropagation();

    const modalElement = document.getElementById(this.modalIdValue);
    if (!modalElement) return;

    const imageEl = modalElement.querySelector('[data-avatar-modal-image]');
    if (imageEl) {
      imageEl.src = this.avatarUrlValue;
    }

    const modal = Modal.getOrCreateInstance(modalElement);
    modal.show();
  }
}
