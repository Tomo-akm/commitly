import { Controller } from '@hotwired/stimulus';
import { Modal } from 'bootstrap';

// リプライコントローラー（ボタンとモーダルを統合）
export default class extends Controller {
  static targets = ['userName', 'postContent', 'parentIdInput', 'replyingToAccountId'];

  static values = {
    postId: Number,
    postContent: String,
    userName: String,
    userAvatarUrl: String,
    userAccountId: String,
  };

  // リプライボタンがクリックされたとき
  openModal(event) {
    event.preventDefault();
    event.stopPropagation();

    const modalElement = document.getElementById('replyModal');
    if (!modalElement) return;

    // モーダルの内容を更新（直接DOMを操作）
    const userNameEl = modalElement.querySelector(
      '[data-reply-target="userName"]'
    );
    const postContentEl = modalElement.querySelector(
      '[data-reply-target="postContent"]'
    );
    const parentIdInputEl = modalElement.querySelector(
      '[data-reply-target="parentIdInput"]'
    );
    const userAvatarEl = modalElement.querySelector(
      '[data-reply-target="userAvatar"]'
    );
    const replyingToAccountIdEl = modalElement.querySelector(
      '[data-reply-target="replyingToAccountId"]'
    );

    if (userNameEl) userNameEl.textContent = this.userNameValue;
    if (postContentEl) postContentEl.textContent = this.postContentValue;
    if (parentIdInputEl) parentIdInputEl.value = this.postIdValue;
    if (userAvatarEl) userAvatarEl.src = this.userAvatarUrlValue;
    if (replyingToAccountIdEl) replyingToAccountIdEl.textContent = `@${this.userAccountIdValue}`;

    // モーダルを開く
    const modal = Modal.getOrCreateInstance(modalElement);
    modal.show();
  }
}
