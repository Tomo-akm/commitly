import { Controller } from '@hotwired/stimulus';
import { Modal } from 'bootstrap';

// フォークコントローラー（ボタンとモーダルを統合）
export default class extends Controller {
  static values = {
    postId: Number,
    postContent: String,
    userName: String,
    userAvatarUrl: String,
    userAccountId: String,
  };

  // フォークボタンがクリックされたとき
  openModal(event) {
    event.preventDefault();
    event.stopPropagation();

    const modalElement = document.getElementById('forkModal');
    if (!modalElement) return;

    // モーダルの内容を更新（直接DOMを操作）
    const userNameEl = modalElement.querySelector(
      '[data-fork-target="userName"]'
    );
    const postContentEl = modalElement.querySelector(
      '[data-fork-target="postContent"]'
    );
    const forkedPostIdInputEl = modalElement.querySelector(
      '[data-fork-target="forkedPostIdInput"]'
    );
    const userAvatarEl = modalElement.querySelector(
      '[data-fork-target="userAvatar"]'
    );
    const userAccountIdEl = modalElement.querySelector(
      '[data-fork-target="userAccountId"]'
    );

    if (userNameEl) userNameEl.textContent = this.userNameValue;
    if (postContentEl) postContentEl.textContent = this.postContentValue;
    if (forkedPostIdInputEl) forkedPostIdInputEl.value = this.postIdValue;
    if (userAvatarEl) userAvatarEl.src = this.userAvatarUrlValue;
    if (userAccountIdEl) userAccountIdEl.textContent = `@${this.userAccountIdValue}`;

    // モーダルを開く
    const modal = Modal.getOrCreateInstance(modalElement);
    modal.show();
  }
}
