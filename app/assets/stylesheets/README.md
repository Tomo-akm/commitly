# スタイルシートモジュール - 使用ガイド

このディレクトリには、commitlyプロダクトのスタイルシートモジュールが含まれています。Color Huntのティール・ミントグリーンテーマを基調とした統一感のあるデザインシステムです。

## 📁 ディレクトリ構造

```
app/assets/stylesheets/
├── abstracts/           # デザイントークンとMixin
│   ├── _variables.scss  # カラー、タイポグラフィ、スペーシング等の変数
│   └── _mixins.scss     # 再利用可能なスタイル定義
├── components/          # コンポーネント
│   ├── _buttons.scss    # ボタンスタイル
│   ├── _cards.scss      # カードスタイル
│   ├── _forms.scss      # フォームスタイル
│   ├── _navbar.scss     # ナビゲーションバー
│   └── _heatmap.scss    # ヒートマップ
├── utilities/           # ユーティリティクラス
│   └── _utilities.scss  # 汎用クラス（margin, padding, etc.）
├── application.scss     # メインエントリーポイント
└── README.md           # このファイル
```

## 🎨 カラーパレット

[Color Hunt](https://colorhunt.co/palette/2e50774da1a979d7bef6f4f0) のティール・ミントグリーンテーマを採用：

### プライマリーカラー（ティール）
- `$primary-light: #d4f1f4` - 薄いティール（背景用）
- `$primary: #4da1a9` - メインティール
- `$primary-dark: #2e5077` - 濃いネイビー（ホバー用）

### セカンダリーカラー（ミントグリーン）
- `$secondary-light: #e6f9f4` - 薄いミント（背景用）
- `$secondary: #79d7be` - ミントグリーン
- `$secondary-dark: #5ab89e` - 濃いミント（ホバー用）

### 背景色
- `$bg-primary: #f6f4f0` - メイン背景（オフホワイト）
- `$bg-secondary: #e6f9f4` - サブ背景（薄いミント）

### ニュートラルカラー
- `$neutral-100` から `$neutral-900` までの5段階

### セマンティックカラー
- `$success` / `$success-dark` - 成功（グリーン）
- `$warning` / `$warning-dark` - 警告（オレンジ）
- `$error` / `$error-dark` - エラー（レッド）
- `$info` / `$info-dark` - 情報（ブルー）

## 🔧 使用方法

### ボタン

```html
<!-- 基本ボタン -->
<button class="btn btn-primary">プライマリーボタン</button>
<button class="btn btn-secondary">セカンダリーボタン</button>

<!-- サイズバリエーション -->
<button class="btn btn-primary btn-sm">小さいボタン</button>
<button class="btn btn-primary btn-md">中サイズボタン</button>
<button class="btn btn-primary btn-lg">大きいボタン</button>

<!-- アウトラインボタン -->
<button class="btn btn-outline-primary">アウトライン</button>

<!-- グラデーションボタン -->
<button class="btn btn-gradient-primary">グラデーション</button>

<!-- アイコン付きボタン -->
<button class="btn btn-primary btn-icon">
  <i class="fas fa-save"></i>
  <span>保存</span>
</button>

<!-- 全幅ボタン -->
<button class="btn btn-primary btn-block">全幅ボタン</button>
```

### カード

```html
<!-- 基本カード -->
<div class="card">
  <div class="card-header">
    <h3 class="card-title">カードタイトル</h3>
    <p class="card-subtitle">サブタイトル</p>
  </div>
  <div class="card-body">
    <p class="card-text">カードの本文がここに入ります。</p>
  </div>
  <div class="card-footer">
    <button class="btn btn-primary">アクション</button>
  </div>
</div>

<!-- ホバーエフェクト付きカード -->
<div class="card card-hover">
  <div class="card-body">
    <p>ホバーすると浮き上がります</p>
  </div>
</div>

<!-- カラーバリエーション -->
<div class="card card-primary">...</div>
<div class="card card-secondary">...</div>

<!-- グラデーションカード -->
<div class="card card-gradient-primary">...</div>
```

### フォーム

```html
<!-- 基本フォーム -->
<div class="form-group">
  <label class="form-label required">ユーザー名</label>
  <input type="text" class="form-control" placeholder="ユーザー名を入力">
  <small class="form-text">ヘルプテキストがここに入ります。</small>
</div>

<!-- エラー状態 -->
<div class="form-group">
  <label class="form-label">メールアドレス</label>
  <input type="email" class="form-control is-invalid">
  <div class="invalid-feedback">正しいメールアドレスを入力してください。</div>
</div>

<!-- チェックボックス -->
<div class="form-check">
  <input type="checkbox" id="check1" class="form-check-input">
  <label for="check1" class="form-check-label">利用規約に同意します</label>
</div>

<!-- スイッチ -->
<div class="form-check form-switch">
  <input type="checkbox" id="switch1" class="form-check-input">
  <label for="switch1" class="form-check-label">通知を有効化</label>
</div>

<!-- インプットグループ -->
<div class="input-group">
  <span class="input-group-text">@</span>
  <input type="text" class="form-control" placeholder="ユーザー名">
</div>
```

### ナビゲーションバー

```html
<!-- 基本ナビバー -->
<nav class="navbar">
  <a href="/" class="navbar-brand">commitly</a>

  <button class="navbar-toggler">
    <span class="navbar-toggler-icon"></span>
  </button>

  <div class="navbar-collapse">
    <ul class="navbar-nav">
      <li class="navbar-item">
        <a href="/" class="navbar-link active">ホーム</a>
      </li>
      <li class="navbar-item">
        <a href="/about" class="navbar-link">について</a>
      </li>
    </ul>
  </div>
</nav>

<!-- グラデーションナビバー -->
<nav class="navbar navbar-gradient">...</nav>

<!-- 固定ナビバー -->
<nav class="navbar navbar-fixed-top">...</nav>
```

### ヒートマップ

```html
<div class="heatmap">
  <div class="heatmap-header">
    <h3 class="heatmap-title">学習記録</h3>
  </div>

  <div class="heatmap-grid">
    <!-- セルをJavaScriptで動的生成 -->
    <div class="heatmap-cell" data-level="3"></div>
    <div class="heatmap-cell" data-level="1"></div>
    <div class="heatmap-cell" data-level="0"></div>
  </div>

  <div class="heatmap-legend">
    <span class="heatmap-legend-label">少ない</span>
    <div class="heatmap-legend-scale">
      <div class="heatmap-legend-item" data-level="0"></div>
      <div class="heatmap-legend-item" data-level="1"></div>
      <div class="heatmap-legend-item" data-level="2"></div>
      <div class="heatmap-legend-item" data-level="3"></div>
      <div class="heatmap-legend-item" data-level="4"></div>
    </div>
    <span class="heatmap-legend-label">多い</span>
  </div>
</div>
```

### ユーティリティクラス

```html
<!-- スペーシング -->
<div class="mt-4 mb-3 p-4">マージン・パディング</div>

<!-- Flexbox -->
<div class="d-flex justify-between align-center gap-3">
  <span>左</span>
  <span>右</span>
</div>

<!-- テキスト -->
<p class="text-center text-primary font-bold text-lg">テキスト装飾</p>

<!-- 背景色 -->
<div class="bg-primary-light p-4 rounded-lg">背景色</div>

<!-- シャドウ -->
<div class="shadow-md rounded">シャドウ付き</div>

<!-- レスポンシブ -->
<div class="d-none d-md-block">中画面以上で表示</div>
```

## 🎯 Mixinの使用

Slimテンプレート内で直接スタイルを書く場合、Mixinを活用できます：

```scss
// カスタムボタンの例
.my-custom-button {
  @include button-base;
  @include button-variant($primary, $primary-dark);
  @include button-size($spacing-3, $spacing-6, $font-size-lg, $border-radius-lg);
}

// カスタムカードの例
.my-custom-card {
  @include card-base;
  @include card-hover;
  padding: $spacing-6;
}

// グラデーション背景
.my-gradient-section {
  @include gradient-primary;
  padding: $spacing-8;
  color: white;
}
```

## 📱 レスポンシブデザイン

```scss
// ブレークポイント
$breakpoint-sm: 576px;
$breakpoint-md: 768px;
$breakpoint-lg: 992px;
$breakpoint-xl: 1200px;

// 使用例
@include breakpoint-up($breakpoint-md) {
  .my-element {
    font-size: $font-size-lg;
  }
}

@include breakpoint-down($breakpoint-sm) {
  .my-element {
    font-size: $font-size-sm;
  }
}
```

## ✨ ベストプラクティス

1. **変数を使用する**: ハードコードされた値ではなく、`_variables.scss`で定義された変数を使用してください。

2. **Mixinを活用する**: 繰り返しのスタイルは`_mixins.scss`のMixinを使用してください。

3. **ユーティリティクラスを優先**: 簡単なスタイルはカスタムCSSを書くよりユーティリティクラスを使用してください。

4. **コンポーネントクラスを使用**: 既存のコンポーネントクラス（`.btn`, `.card`など）を活用してください。

5. **カラーパレットを守る**: 統一感を保つため、定義されたカラーパレットから外れないようにしてください。

## 🔄 アセットのコンパイル

変更を適用するには、Railsアセットをプリコンパイルする必要があります：

```bash
# 開発環境（Dockerコンテナ内で実行）
docker compose exec web rails assets:precompile

# 本番環境
RAILS_ENV=production rails assets:precompile
```

## 🐛 トラブルシューティング

### スタイルが適用されない

1. アセットがコンパイルされているか確認
2. ブラウザのキャッシュをクリア
3. Railsサーバーを再起動

### 変数が見つからないエラー

- `application.scss`で正しい順序でインポートされているか確認
- `abstracts/`が他のモジュールより先に読み込まれている必要があります

## 📝 メンテナンス

新しいコンポーネントやユーティリティを追加する場合：

1. 適切なディレクトリにファイルを作成
2. `application.scss`でインポート
3. このREADMEに使用例を追加

## 📚 参考リンク

- [Color Hunt パレット](https://colorhunt.co/palette/2e50774da1a979d7bef6f4f0)
- [Bootstrap 5 Documentation](https://getbootstrap.com/docs/5.0/)
- [SASS Documentation](https://sass-lang.com/documentation)
