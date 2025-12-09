# Solid Queue & Solid Cable セットアップガイド

このドキュメントでは、Solid Queue（バックグラウンドジョブ）とSolid Cable（WebSocket/ActionCable）のセットアップ手順を環境別に説明します。

## 概要

- **Solid Queue**: バックグラウンドジョブ処理システム（Sidekiq/Resque代替）
- **Solid Cable**: ActionCableのバックエンド（Redis代替）
- **メリット**: PostgreSQLだけで完結、追加インフラ不要

## 1. 他の開発者のローカル環境セットアップ

### 前提条件
- Docker & Docker Composeがインストール済み
- リポジトリを最新の状態にpull済み

### 手順

#### 1.1 最新コードを取得
```bash
git checkout main
git pull origin main
```

#### 1.2 データベースマイグレーション
```bash
# queueとcableのスキーマを適用
docker compose exec web rails db:schema:load:queue
docker compose exec web rails db:schema:load:cable

# または、db:prepareで全て適用
docker compose exec web rails db:prepare
```

#### 1.3 確認：テーブルが作成されているか
```bash
docker compose exec -T db psql -U commitly -d commitly_development -c "\dt solid_*"
```

以下のテーブルが表示されればOK：
- solid_queue_*（11テーブル）
- solid_cable_messages（1テーブル）

#### 1.4 Workerコンテナを起動
```bash
# docker-compose.ymlにworkerが既に追加されているので
docker compose up -d worker

# 全て再起動する場合
docker compose down
docker compose up -d
```

#### 1.5 動作確認
```bash
# ジョブの状態確認
docker compose exec -T db psql -U commitly -d commitly_development -c \
  "SELECT id, class_name, finished_at FROM solid_queue_jobs ORDER BY created_at DESC LIMIT 5;"

# Workerのログ確認
docker compose logs worker --tail 50
```

### トラブルシューティング

**テーブルが作成されない場合**
```bash
# schema.rbを確認
docker compose exec web rails db:schema:dump

# 手動でマイグレーション実行
docker compose exec web rails db:migrate
docker compose exec web rails db:migrate:queue
docker compose exec web rails db:migrate:cable
```

**Workerが起動しない場合**
```bash
# Workerコンテナのログ確認
docker compose logs worker

# Workerを再起動
docker compose restart worker
```

---

## 2. 本番環境（Render）でのセットアップ

### 前提条件
- RenderでPostgreSQLデータベースが作成済み
- DATABASE_URLが環境変数に設定済み

### 手順

#### 2.1 デプロイ前の確認
```bash
# productionではsolid_cableを使用（config/cable.yml確認）
# productionではsolid_queueを使用（config/environments/production.rb確認）
```

#### 2.2 Renderでのデプロイ
通常通りgit pushでデプロイ：
```bash
git push origin main
```

#### 2.3 マイグレーション実行
Renderは自動でマイグレーションを実行しますが、手動で確認する場合：
```bash
# Render Shellで
rails db:migrate
rails db:schema:load:queue
rails db:schema:load:cable
```

#### 2.4 Workerプロセスの設定

**オプションA: Puma内でジョブ実行（小規模アプリ推奨）**

Renderの環境変数に追加：
```
SOLID_QUEUE_IN_PUMA=true
```

これでWebサーバープロセス内でSolid Queueが実行されます。

**オプションB: 専用Workerプロセス（推奨・スケーラブル）**

Renderで新しいBackground Workerを追加：
1. Renderダッシュボード → Services → New Background Worker
2. Build Command: `bundle install`
3. Start Command: `bundle exec bin/jobs`
4. Environment: Production
5. 環境変数をWebサーバーと同じに設定

#### 2.5 動作確認

Render Shell（またはRails Console）で：
```ruby
# ジョブの確認
ActiveRecord::Base.connection.execute("SELECT id, class_name, finished_at FROM solid_queue_jobs ORDER BY created_at DESC LIMIT 5;")

# テーブル確認
ActiveRecord::Base.connection.tables.select { |t| t.start_with?('solid_') }
```

---

## 3. Kamal2でのデプロイ

### 前提条件
- Kamal2がインストール済み（`gem install kamal`）
- `.kamal/secrets`に必要な認証情報が設定済み
- デプロイ先サーバーにSSH接続可能

### 手順

#### 3.1 Kamal設定ファイルの確認

`config/deploy.yml`を編集：

```yaml
# Workerプロセスを有効化
servers:
  web:
    - 192.168.0.1  # 本番サーバーのIP
  job:
    hosts:
      - 192.168.0.1  # 同じサーバーまたは別サーバー
    cmd: bundle exec bin/jobs

# 環境変数設定
env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL  # PostgreSQL接続URL
  clear:
    # 小規模な場合はPuma内で実行（jobセクション不要）
    # SOLID_QUEUE_IN_PUMA: true

    # Workerの並列数（jobセクション使用時）
    JOB_CONCURRENCY: 2

    RAILS_ENV: production
```

#### 3.2 データベースマイグレーション

デプロイ前に設定を追加（`config/deploy.yml`）：

```yaml
# デプロイフックでマイグレーション実行
# .kamal/hooks/post-deploy を作成
```

または、初回デプロイ後に手動実行：
```bash
# Kamal経由でマイグレーション
kamal app exec 'rails db:migrate'
kamal app exec 'rails db:schema:load:queue'
kamal app exec 'rails db:schema:load:cable'
```

#### 3.3 初回デプロイ
```bash
# 設定確認
kamal config

# デプロイ実行
kamal setup
kamal deploy
```

#### 3.4 Workerの起動確認
```bash
# Workerコンテナのログ確認
kamal app logs -r job

# 全コンテナの状態確認
kamal app details
```

#### 3.5 動作確認
```bash
# コンソールに接続
kamal app exec --interactive 'bin/rails console'

# ジョブの確認
> SolidQueue::Job.last(5)
> ActiveRecord::Base.connection.tables.grep(/solid_/)
```

### Kamal2の便利なコマンド

```bash
# アプリケーションの再起動
kamal app restart

# Workerのみ再起動
kamal app restart -r job

# ログ確認
kamal app logs          # Webサーバー
kamal app logs -r job   # Worker

# コンソール接続
kamal console

# データベースコンソール
kamal dbc

# シェル接続
kamal shell
```

---

## 4. 各環境の設定まとめ

### ローカル開発（Docker Compose）
- **Queue**: solid_queue
- **Cable**: solid_cable
- **Worker**: 専用コンテナ（`docker-compose.yml`のworkerサービス）
- **DB**: 同じPostgreSQL（commitly_development）

### Render
- **Queue**: solid_queue
- **Cable**: solid_cable
- **Worker**: Background Worker（または`SOLID_QUEUE_IN_PUMA=true`）
- **DB**: Render PostgreSQL

### Kamal2
- **Queue**: solid_queue
- **Cable**: solid_cable
- **Worker**: 専用コンテナ（`config/deploy.yml`のjobセクション）
- **DB**: 外部PostgreSQL（またはKamal Accessory）

---

## 5. 共通の注意点

### 5.1 データベース設定
- `config/database.yml`で各環境に`queue`と`cable`の設定が必要
- 開発/テストは同じDBを使用、本番は同じDBまたは別DB可能

### 5.2 マイグレーション
- 通常の`rails db:migrate`では不十分
- `rails db:schema:load:queue`と`rails db:schema:load:cable`が必要
- または`rails db:prepare`で全て適用

### 5.3 ActionCableの動作
- 開発環境でも`solid_cable`を使用（asyncは別プロセスで動作しない）
- Workerからのブロードキャストにはsolid_cableが必須

### 5.4 ジョブの実行
```ruby
# 非同期実行（Workerで処理）
EntrySheetAdviceJob.perform_later(args)

# 即座に実行（開発/デバッグ用）
EntrySheetAdviceJob.perform_now(args)
```

### 5.5 モニタリング
```sql
-- ジョブの状態確認
SELECT id, class_name, queue_name, finished_at, created_at
FROM solid_queue_jobs
ORDER BY created_at DESC LIMIT 10;

-- 失敗したジョブ
SELECT j.id, j.class_name, f.error
FROM solid_queue_jobs j
JOIN solid_queue_failed_executions f ON j.id = f.job_id;

-- 実行中のジョブ
SELECT j.id, j.class_name, c.created_at
FROM solid_queue_jobs j
JOIN solid_queue_claimed_executions c ON j.id = c.job_id
WHERE j.finished_at IS NULL;
```

---

## 6. トラブルシューティング

### ジョブがキューに入るが実行されない
- Workerプロセスが起動しているか確認
- `docker compose logs worker` / `kamal app logs -r job`でログ確認
- データベース接続が正しいか確認

### リアルタイム更新が反映されない
- ActionCableがsolid_cableを使用しているか確認（`config/cable.yml`）
- ブラウザのコンソールでWebSocket接続を確認
- `solid_cable_messages`テーブルにメッセージが保存されているか確認

### マイグレーションエラー
```bash
# スキーマファイルを確認
ls -la db/*_schema.rb

# 手動で再適用
rails db:schema:load:queue
rails db:schema:load:cable
```

---

## 参考リンク
- [Solid Queue公式ドキュメント](https://github.com/rails/solid_queue)
- [Solid Cable公式ドキュメント](https://github.com/rails/solid_cable)
- [Kamal2公式ドキュメント](https://kamal-deploy.org/)