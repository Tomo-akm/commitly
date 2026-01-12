import { Controller } from "@hotwired/stimulus";
import Cropper from "cropperjs";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = [
    "input",
    "image",
    "placeholder",
    "resetButton",
    "menu",
    "previewArea",
    "modal",
    "cropperImage",
    "cropperZoom",
    "loader",
  ];
  static values = {
    originalSrc: String,
    deleteUrl: String,
    hasOriginal: Boolean,
  };

  connect() {
    if (this.hasImageTarget) {
      this.originalSrcValue = this.imageTarget.src;
    }
    this.cropper = null;
    this.originalFile = null;
    this.hasNewFile = false;
    this.menuOpen = false;
    this.bsModal = null;

    // 外側クリックでメニューを閉じる
    this.handleOutsideClick = this.handleOutsideClick.bind(this);
    document.addEventListener("click", this.handleOutsideClick);

    // Bootstrap Modalの初期化とイベント設定
    if (this.hasModalTarget) {
      this.bsModal = new Modal(this.modalTarget);
      this.modalTarget.addEventListener("shown.bs.modal", () =>
        this.initCropper(),
      );
      this.modalTarget.addEventListener("hidden.bs.modal", () =>
        this.onModalHidden(),
      );
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick);
    this.destroyCropper();
    if (this.bsModal) {
      this.bsModal.dispose();
    }
  }

  handleOutsideClick(event) {
    if (!this.menuOpen) return;
    if (!this.element.contains(event.target)) {
      this.hideMenu();
    }
  }

  toggleMenu(event) {
    event.stopPropagation();
    if (this.menuOpen) {
      this.hideMenu();
    } else {
      this.showMenu();
    }
  }

  showMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.style.display = "flex";
      this.menuOpen = true;
    }
  }

  hideMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.style.display = "none";
      this.menuOpen = false;
    }
  }

  triggerFileInput(event) {
    event.stopPropagation();
    this.hideMenu();
    this.inputTarget.click();
  }

  openCropper() {
    const file = this.inputTarget.files[0];
    if (!file) return;

    this.originalFile = file;
    this.hasNewFile = true;

    const reader = new FileReader();
    reader.onload = (e) => {
      // 画像をセット
      this.cropperImageTarget.src = e.target.result;
      // Bootstrap Modalを開く（shown.bs.modalイベントでCropperを初期化）
      this.bsModal.show();
    };
    reader.readAsDataURL(file);
  }

  initCropper() {
    this.destroyCropper();

    this.cropper = new Cropper(this.cropperImageTarget, {
      aspectRatio: 1,
      viewMode: 1,
      dragMode: "move",
      autoCropArea: 1,
      cropBoxMovable: false,
      cropBoxResizable: false,
      toggleDragModeOnDblclick: false,
      guides: false,
      center: false,
      highlight: false,
      background: false,
      ready: () => {
        // ローダーを非表示
        if (this.hasLoaderTarget) this.loaderTarget.style.display = "none";

        // 初期ズーム値を取得してスライダーに反映（左端が初期値、右で拡大）
        if (this.hasCropperZoomTarget) {
          const imageData = this.cropper.getImageData();
          const initialZoom = imageData.width / imageData.naturalWidth;
          this.cropperZoomTarget.min = initialZoom;
          this.cropperZoomTarget.max = initialZoom * 3;
          this.cropperZoomTarget.value = initialZoom;
        }
      },
      zoom: () => {
        // ズームスライダーと同期
        if (this.hasCropperZoomTarget && this.cropper) {
          const imageData = this.cropper.getImageData();
          const currentZoom = imageData.width / imageData.naturalWidth;
          this.cropperZoomTarget.value = currentZoom;
        }
      },
    });
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy();
      this.cropper = null;
    }
  }

  onModalHidden() {
    this.destroyCropper();
    // 次回用にローダー表示にリセット
    if (this.hasLoaderTarget) this.loaderTarget.style.display = "";
  }

  closeCropper() {
    this.bsModal.hide();
    // ファイル入力をリセット
    this.inputTarget.value = "";
    this.hasNewFile = false;
    this.originalFile = null;
  }

  zoomCropper() {
    if (!this.cropper || !this.hasCropperZoomTarget) return;
    const zoomValue = parseFloat(this.cropperZoomTarget.value);
    this.cropper.zoomTo(zoomValue);
  }

  applyCrop() {
    if (!this.cropper) return;

    // 円形クロップした画像を取得
    const canvas = this.cropper.getCroppedCanvas({
      width: 400,
      height: 400,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: "high",
    });

    canvas.toBlob(
      (blob) => {
        // ファイル入力にセット
        const fileName = this.originalFile?.name || "avatar.png";
        const file = new File([blob], fileName, { type: "image/png" });
        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        this.inputTarget.files = dataTransfer.files;

        // プレビュー画像を更新
        const croppedImageUrl = canvas.toDataURL("image/png");

        if (this.hasImageTarget) {
          this.imageTarget.src = croppedImageUrl;
        } else if (this.hasPlaceholderTarget) {
          const img = document.createElement("img");
          img.src = croppedImageUrl;
          img.className = "avatar-upload__image";
          img.dataset.avatarPreviewTarget = "image";
          this.placeholderTarget.replaceWith(img);
        }

        this.showResetButton();
        this.bsModal.hide();
      },
      "image/png",
      0.9,
    );
  }

  resetToDefault(event) {
    if (event) event.stopPropagation();
    this.hideMenu();

    // 新しいファイルがあればまずクリア
    if (this.hasNewFile) {
      this.inputTarget.value = "";
      this.hasNewFile = false;
      this.originalFile = null;
    }

    // サーバーにオリジナルアバターがあれば削除（確認後）
    if (this.hasOriginalValue) {
      this.deleteFromServer();
    } else {
      // サーバーにもオリジナルがなければプレースホルダーに戻す
      this.showPlaceholder();
    }
  }

  showPlaceholder() {
    if (this.hasImageTarget) {
      const placeholder = document.createElement("div");
      placeholder.className = "avatar-upload__placeholder";
      placeholder.dataset.avatarPreviewTarget = "placeholder";
      placeholder.innerHTML = '<i class="fas fa-user"></i>';
      this.imageTarget.replaceWith(placeholder);
    }
    this.hideResetButton();
  }

  deleteFromServer() {
    if (!this.deleteUrlValue) return;

    if (confirm("アバター画像を削除してもよろしいですか？")) {
      fetch(this.deleteUrlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
          Accept: "text/vnd.turbo-stream.html",
        },
      })
        .then((response) => {
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }
          return response.text();
        })
        .then((html) => {
          Turbo.renderStreamMessage(html);
          this.hasOriginalValue = false;
          this.originalSrcValue = "";
          this.showPlaceholder();
        })
        .catch(() => {
          alert("アバター画像の削除に失敗しました。");
        });
    }
  }

  showResetButton() {
    if (this.hasResetButtonTarget) {
      this.resetButtonTarget.style.display = "inline-flex";
    }
  }

  hideResetButton() {
    if (this.hasResetButtonTarget) {
      this.resetButtonTarget.style.display = "none";
    }
  }
}
