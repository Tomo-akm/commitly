# commitly

Rails アプリケーション

## 環境構築

### 必要なもの
- Docker
- Docker Compose

### 初回セットアップ

1. リポジトリをクローン
```bash
git clone <repository-url>
cd commitly
```

2. Dockerイメージをビルド
```bash
docker compose build
```

3. データベースのセットアップ
```bash
docker compose run --rm web bin/rails db:create
docker compose run --rm web bin/rails db:migrate
```

4. アプリケーションの起動
```bash
docker compose up
```

アプリケーションは http://localhost:3000 でアクセスできます。

## 日常の開発手順

### コンテナの起動・停止

```bash
# コンテナを起動（フォアグラウンド）
docker compose up

# コンテナを起動（バックグラウンド）
docker compose up -d

# コンテナを停止して削除
docker compose down
```

### コンテナの状態確認

```bash
# 起動中のコンテナを確認
docker compose ps

# ログを確認
docker compose logs

# 特定のサービスのログを確認
docker compose logs web
docker compose logs db

# ログをリアルタイムで追跡
docker compose logs -f web
```

### Dockerイメージの再ビルド

Gemfile や Dockerfile を変更した場合は、イメージを再ビルドします。

```bash
# イメージを再ビルド
docker compose build

# キャッシュを使わずに再ビルド
docker compose build --no-cache

# 再ビルドして起動
docker compose up --build
```

## コマンドの実行方法

Rails や bundle などのコマンドを実行する方法は2つあります。

### 方法1: コンテナの外から実行（推奨）

コンテナに入らずに、ホストマシンから直接コマンドを実行できます。

```bash
# Railsコマンド
docker compose exec web bin/rails console
docker compose exec web bin/rails routes
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed
docker compose exec web bin/rails db:rollback

# bundle コマンド
docker compose exec web bundle install
docker compose exec web bundle update
docker compose exec web bundle exec rspec

# rake タスク
docker compose exec web bin/rails db:migrate:status

# テストの実行
docker compose exec web bin/rails test
docker compose exec web bundle exec rspec

# アセットのコンパイル
docker compose exec web bin/rails assets:precompile

# Sassのビルド
docker compose exec web bin/rails dartsass:build

# Sassの自動監視（開発中）
docker compose exec web bin/rails dartsass:watch
```

**注意:** コンテナが起動していない場合は、`docker compose run --rm web <command>` を使用してください。

```bash
# コンテナが起動していない場合
docker compose run --rm web bin/rails db:create
docker compose run --rm web bundle install
```

### 方法2: コンテナの中に入って実行

コンテナ内でシェルを起動して、直接コマンドを実行することもできます。

```bash
# webコンテナに入る
docker compose exec web bash

# コンテナ内で以下のようにコマンドを実行
# (プロンプトが root@xxxxx:/webapp# のようになります)

bin/rails console
bin/rails routes
bin/rails db:migrate
bundle install
bundle exec rspec
exit  # コンテナから出る
```

**コンテナが起動していない場合:**
```bash
docker compose run --rm web bash
```

### データベース操作

```bash
# PostgreSQLコンテナに入る
docker compose exec db psql -U commitly -d commitly_development

# データベースをリセット
docker compose exec web bin/rails db:reset

# マイグレーションの状態を確認
docker compose exec web bin/rails db:migrate:status
```

### Sassのビルド

このプロジェクトでは、BootstrapとカスタムスタイルにDart Sassを使用しています。

#### 構成

- **ソースファイル**: `app/assets/stylesheets/application.scss`
- **ビルド先**: `app/assets/builds/application.css`（自動生成）

#### ビルドコマンド

```bash
# 1回だけビルド
docker compose exec web bin/rails dartsass:build

# ファイル変更を監視して自動ビルド（開発時）
docker compose exec web bin/rails dartsass:watch
```

#### 注意事項

- `application.scss`を編集した後は、必ず`dartsass:build`を実行してください
- 開発中は`dartsass:watch`を別ターミナルで起動しておくと便利です
- `app/assets/builds/application.css`は自動生成されるため、直接編集しないでください
- `Procfile.dev`には`dartsass:watch`が含まれているため、`bin/dev`で起動すると自動監視されます

#### スタイルの編集

すべてのカスタムスタイルは`app/assets/stylesheets/application.scss`に記述してください：

```scss
// Bootstrap 5のインポート
@import "bootstrap";

// カスタムスタイル
.navbar {
  // あなたのスタイル
}
```

## 開発ルール

### ブランチ命名規則

ブランチ名は以下の形式で作成してください:

```
<プレフィックス>/<Issue番号>/<内容>
```

#### プレフィックスの種類

- `feat/` - 新機能の追加
- `fix/` - バグ修正
- `refactor/` - リファクタリング
- `docs/` - ドキュメントのみの変更
- `test/` - テストの追加・修正
- `chore/` - ビルドプロセスやツールの変更

#### 例

```bash
# 新機能の追加
git checkout -b feat/123/add-user-authentication

# バグ修正
git checkout -b fix/456/fix-login-error

# リファクタリング
git checkout -b refactor/789/improve-database-queries

# ドキュメント更新
git checkout -b docs/12/update-readme

# テストの追加
git checkout -b test/34/add-user-model-tests

# その他の作業
git checkout -b chore/56/update-dependencies
```

#### 注意事項

- Issue番号はGitHubのIssue番号を使用してください
- 内容は簡潔で分かりやすい英語（小文字、ハイフン区切り）で記述してください
- 日本語を使用する場合はローマ字でも構いません
