import { Controller } from '@hotwired/stimulus';
import { Modal } from 'bootstrap';

// 実績モーダルを開いて詳細を差し替える
export default class extends Controller {
  static values = {
    label: String,
    hint: String,
    badge: String,
    achieved: Boolean,
    achievedAt: String,
  };

  open(event) {
    event.preventDefault();
    event.stopPropagation();

    const modalElement = document.getElementById('achievementModal');
    if (!modalElement) return;

    const badgeEl = modalElement.querySelector('[data-achievement-modal-target="badge"]');
    const titleEl = modalElement.querySelector('[data-achievement-modal-target="title"]');
    const hintEl = modalElement.querySelector('[data-achievement-modal-target="hint"]');
    const statusPillEl = modalElement.querySelector('[data-achievement-modal-target="statusPill"]');
    const statusEl = modalElement.querySelector('[data-achievement-modal-target="status"]');
    const dateEl = modalElement.querySelector('[data-achievement-modal-target="date"]');

    if (badgeEl) {
      badgeEl.src = this.badgeValue;
      badgeEl.alt = `${this.labelValue}バッジ`;
    }
    if (titleEl) titleEl.textContent = this.labelValue;
    if (hintEl) hintEl.textContent = this.hintValue;

    const achievedText = this.achievedValue ? '達成済み' : '未達成';
    if (statusPillEl) {
      statusPillEl.textContent = achievedText;
      statusPillEl.classList.toggle('is-achieved', this.achievedValue);
      statusPillEl.classList.toggle('is-locked', !this.achievedValue);
    }
    if (statusEl) {
      statusEl.textContent = achievedText;
      statusEl.classList.toggle('is-achieved', this.achievedValue);
      statusEl.classList.toggle('is-locked', !this.achievedValue);
    }
    if (dateEl) {
      dateEl.textContent = this.achievedValue ? this.achievedAtValue : '未達成';
    }

    const modal = Modal.getOrCreateInstance(modalElement);
    modal.show();
  }
}
