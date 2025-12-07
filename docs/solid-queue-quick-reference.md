# Solid Queue/Cable クイックリファレンス

## 🚀 他の開発者向けセットアップ（3ステップ）

```bash
# 1. コードを取得
git pull origin main

# 2. スキーマ適用
docker compose exec web rails db:schema:load:queue
docker compose exec web rails db:schema:load:cable

# 3. Workerを起動
docker compose up -d worker
```

確認：
```bash
docker compose ps  # workerが起動しているか確認
docker compose logs worker  # ログ確認
```

---

## 🏗️ Render デプロイ（2パターン）

### パターンA: Puma内で実行（小規模）
環境変数に追加：
```
SOLID_QUEUE_IN_PUMA=true
```

### パターンB: 専用Worker（推奨）
1. Render → New Background Worker
2. Start Command: `bundle exec bin/jobs`
3. 環境変数をWebと同じに設定

---

## 🚢 Kamal2 デプロイ

```bash
# 初回セットアップ
kamal setup

# マイグレーション
kamal app exec 'rails db:schema:load:queue'
kamal app exec 'rails db:schema:load:cable'

# デプロイ
kamal deploy

# ログ確認
kamal app logs -r job
```

---

## 🔍 動作確認コマンド

### ジョブの状態確認
```sql
SELECT id, class_name, queue_name, finished_at, created_at
FROM solid_queue_jobs
ORDER BY created_at DESC LIMIT 5;
```

### テーブル確認
```bash
docker compose exec -T db psql -U commitly -d commitly_development -c "\dt solid_*"
```

### ログ確認
```bash
# ローカル
docker compose logs worker -f

# Kamal
kamal app logs -r job -f
```

---

## 📊 モニタリングSQL

### 失敗したジョブ
```sql
SELECT j.id, j.class_name, f.error
FROM solid_queue_jobs j
JOIN solid_queue_failed_executions f ON j.id = f.job_id
ORDER BY j.created_at DESC;
```

### 実行中のジョブ
```sql
SELECT j.id, j.class_name, j.created_at
FROM solid_queue_jobs j
JOIN solid_queue_claimed_executions c ON j.id = c.job_id
WHERE j.finished_at IS NULL;
```

### ジョブ統計
```sql
SELECT
  class_name,
  COUNT(*) as total,
  COUNT(finished_at) as finished,
  COUNT(*) - COUNT(finished_at) as pending
FROM solid_queue_jobs
GROUP BY class_name;
```

---

## 🛠️ トラブルシューティング

### Worker が起動しない
```bash
# ログ確認
docker compose logs worker

# 再起動
docker compose restart worker
```

### ジョブが実行されない
1. Workerが起動しているか確認
2. データベース接続を確認
3. ジョブがキューに入っているか確認

### リアルタイム更新されない
1. ActionCableがsolid_cableを使用しているか（`config/cable.yml`）
2. ブラウザのWebSocket接続を確認
3. `turbo_stream_from`が設定されているか確認

---

詳細は [solid-queue-setup-guide.md](./solid-queue-setup-guide.md) を参照してください。