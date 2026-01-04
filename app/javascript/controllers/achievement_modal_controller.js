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
    series: String,
    seriesLabel: String,
  };

  open(event) {
    event.preventDefault();
    event.stopPropagation();

    const modalElement = this.getModalElement();
    if (!modalElement) return;

    this.updateBadge(modalElement);
    this.updateTitle(modalElement);
    this.updateHint(modalElement);
    this.updateSeries(modalElement);
    this.updateStatus(modalElement);
    this.updateDate(modalElement);

    this.showModal(modalElement);
  }

  getModalElement() {
    return document.getElementById('achievementModal');
  }

  getTarget(modalElement, targetName) {
    return modalElement.querySelector(`[data-achievement-modal-target="${targetName}"]`);
  }

  updateBadge(modalElement) {
    const badgeEl = this.getTarget(modalElement, 'badge');
    if (!badgeEl) return;

    if (this.badgeValue) badgeEl.src = this.badgeValue;
    badgeEl.alt = this.labelValue ? `${this.labelValue}バッジ` : '実績バッジ';

    // アニメーションをトリガー
    this.triggerBadgeAnimation(badgeEl);
  }

  triggerBadgeAnimation(badgeEl) {
    // 既存のアニメーションクラスを削除（リセット）
    badgeEl.classList.remove('is-animating');

    // リフローを強制してアニメーションを再トリガー
    void badgeEl.offsetWidth;

    // アニメーションクラスを追加
    badgeEl.classList.add('is-animating');

    // アニメーション終了後にクラスを削除
    badgeEl.addEventListener('animationend', () => {
      badgeEl.classList.remove('is-animating');
    }, { once: true });
  }


  updateTitle(modalElement) {
    const titleEl = this.getTarget(modalElement, 'title');
    if (titleEl) {
      titleEl.textContent = this.labelValue;
    }
  }

  updateHint(modalElement) {
    const hintEl = this.getTarget(modalElement, 'hint');
    if (hintEl) {
      hintEl.textContent = this.hintValue;
    }
  }

  updateSeries(modalElement) {
    const seriesEl = this.getTarget(modalElement, 'series');
    if (!seriesEl) return;

    const seriesLabel = this.seriesLabelValue || '';
    seriesEl.textContent = seriesLabel;
    seriesEl.classList.toggle('is-hidden', !seriesLabel);
  }

  updateStatus(modalElement) {
    const achievedText = this.achievedValue ? '達成済み' : '未達成';

    const statusPillEl = this.getTarget(modalElement, 'statusPill');
    if (statusPillEl) {
      statusPillEl.textContent = achievedText;
      this.toggleStatusClasses(statusPillEl);
    }

    const statusEl = this.getTarget(modalElement, 'status');
    if (statusEl) {
      statusEl.textContent = achievedText;
      this.toggleStatusClasses(statusEl);
    }
  }

  updateDate(modalElement) {
    const dateEl = this.getTarget(modalElement, 'date');
    if (!dateEl) return;

    dateEl.textContent = this.achievedValue ? this.achievedAtValue : '未達成';
  }

  toggleStatusClasses(element) {
    element.classList.toggle('is-achieved', this.achievedValue);
    element.classList.toggle('is-locked', !this.achievedValue);
  }

  showModal(modalElement) {
    const modal = Modal.getOrCreateInstance(modalElement);
    modal.show();
  }
}
