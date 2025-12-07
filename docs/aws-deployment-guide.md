# AWS デプロイ手順書（最小構成・初心者向け）

**目標**: このアプリを AWS EC2 + RDS で動かす（月額 $0〜15、無料枠活用）

**所要時間**: 約 1〜2 時間

---

## 前提条件

- [x] AWS アカウント作成済み
- [x] $100 クレジット取得済み
- [ ] ローカル環境で Docker が動作している
- [ ] ローカル環境で `kamal` コマンドが使える（`gem install kamal`）

---

## 全体構成

```
Internet
   ↓
[Elastic IP] (固定IPアドレス、無料)
   ↓
[EC2 t3.micro] (Ubuntu 24.04 + Docker)
   ├─ Rails アプリ (Docker コンテナ)
   └─ Puma サーバー
   ↓
[RDS PostgreSQL db.t4g.micro] (無料枠)
```

**月額コスト見積もり**:
- EC2 t3.micro: $0（初年度無料枠）
- RDS db.t4g.micro: $0（初年度無料枠、20GB まで）
- Elastic IP: $0（EC2 にアタッチしている限り）
- データ転送: $1〜3
- **合計: $1〜3/月（無料枠内）**

無料枠終了後:
- EC2 t3.micro: ~$7/月
- RDS db.t4g.micro: ~$13/月
- **合計: ~$20〜25/月**

---

## ステップ 1: IAM ユーザー作成（5分）

### 1-1. IAM ダッシュボードへ移動

AWS コンソール → 検索バーで「IAM」→「ユーザー」→「ユーザーを作成」

### 1-2. ユーザー情報

- **ユーザー名**: `kamal-deploy`
- **アクセスの種類**:
  - ✅ プログラムによるアクセス（アクセスキー）
  - ✅ AWS マネジメントコンソールへのアクセス

### 1-3. アクセス許可

「ポリシーを直接アタッチ」を選択し、以下をチェック:
- `AmazonEC2FullAccess`
- `AmazonRDSFullAccess`
- `AmazonVPCFullAccess`

### 1-4. アクセスキーをダウンロード

**重要**: `credentials.csv` をダウンロードして安全に保管

ローカルで AWS CLI 設定:
```bash
aws configure
# AWS Access Key ID: （ダウンロードした CSV から）
# AWS Secret Access Key: （ダウンロードした CSV から）
# Default region name: ap-northeast-1
# Default output format: json
```

---

## ステップ 2: EC2 キーペア作成（3分）

### 2-1. EC2 ダッシュボードへ

AWS コンソール → EC2 → 左メニュー「キーペア」→「キーペアを作成」

### 2-2. 設定

- **名前**: `commitly-key`
- **キーペアのタイプ**: RSA
- **プライベートキーファイル形式**: .pem

### 2-3. ダウンロード

`commitly-key.pem` がダウンロードされる

```bash
# 権限を変更（必須）
chmod 400 ~/Downloads/commitly-key.pem

# SSH 用ディレクトリに移動
mv ~/Downloads/commitly-key.pem ~/.ssh/
```

---

## ステップ 3: セキュリティグループ作成（10分）

### 3-1. EC2 用セキュリティグループ

EC2 → セキュリティグループ → 「セキュリティグループを作成」

**基本情報**:
- **セキュリティグループ名**: `commitly-web-sg`
- **説明**: `Security group for Commitly web server`
- **VPC**: デフォルト VPC

**インバウンドルール**:

| タイプ | プロトコル | ポート範囲 | ソース | 説明 |
|--------|-----------|-----------|--------|------|
| SSH | TCP | 22 | マイIP | SSH アクセス |
| HTTP | TCP | 80 | 0.0.0.0/0 | HTTP アクセス |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS アクセス |
| カスタム TCP | TCP | 3000 | 0.0.0.0/0 | Rails 開発用（後で削除） |

**アウトバウンドルール**: デフォルト（すべて許可）のまま

### 3-2. RDS 用セキュリティグループ

もう一度「セキュリティグループを作成」

**基本情報**:
- **セキュリティグループ名**: `commitly-db-sg`
- **説明**: `Security group for Commitly database`
- **VPC**: デフォルト VPC

**インバウンドルール**:

| タイプ | プロトコル | ポート範囲 | ソース | 説明 |
|--------|-----------|-----------|--------|------|
| PostgreSQL | TCP | 5432 | `commitly-web-sg` のセキュリティグループ ID | EC2 からの接続のみ |

**手順**:
1. ソースタイプで「カスタム」を選択
2. 検索ボックスに `commitly-web-sg` と入力
3. 表示されたセキュリティグループ ID を選択

---

## ステップ 4: RDS PostgreSQL 作成（15分）

### 4-1. RDS ダッシュボードへ

AWS コンソール → RDS → 「データベースの作成」

### 4-2. エンジンオプション

- **エンジンのタイプ**: PostgreSQL
- **バージョン**: PostgreSQL 16.x（最新）

### 4-3. テンプレート

- **テンプレート**: ✅ 無料利用枠

### 4-4. 設定

- **DB インスタンス識別子**: `commitly-db`
- **マスターユーザー名**: `postgres`（デフォルト）
- **マスターパスワード**: 強力なパスワードを設定（メモ必須！）
- **パスワードの確認**: 再入力

### 4-5. インスタンスの設定

- **DB インスタンスクラス**: db.t4g.micro（無料枠）
- **ストレージタイプ**: 汎用 SSD (gp3)
- **ストレージ割り当て**: 20 GB
- **ストレージの自動スケーリング**: ❌ 無効（コスト管理のため）

### 4-6. 接続

- **コンピューティングリソース**: EC2 コンピューティングリソースに接続しない
- **VPC**: デフォルト VPC
- **パブリックアクセス**: ❌ なし
- **VPC セキュリティグループ**: 既存を選択 → `commitly-db-sg`
- **アベイラビリティーゾーン**: 指定なし

### 4-7. データベース認証

- **データベース認証**: パスワード認証

### 4-8. 追加設定

- **最初のデータベース名**: `commitly_production`
- **バックアップ**:
  - 自動バックアップ有効
  - 保持期間: 7 日
- **暗号化**: ✅ 有効
- **マイナーバージョン自動アップグレード**: ✅ 有効

### 4-9. 作成

「データベースの作成」をクリック → 作成完了まで約 5〜10 分待つ

### 4-10. エンドポイント確認

作成完了後、RDS → データベース → `commitly-db` → 接続とセキュリティ

**エンドポイント**をコピー（例: `commitly-db.xxxxxx.ap-northeast-1.rds.amazonaws.com`）

---

## ステップ 5: EC2 インスタンス作成（10分）

### 5-1. EC2 ダッシュボードへ

AWS コンソール → EC2 → 「インスタンスを起動」

### 5-2. 名前とタグ

- **名前**: `commitly-web`

### 5-3. アプリケーションおよび OS イメージ（AMI）

- **AMI**: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
- **アーキテクチャ**: 64 ビット (x86)

### 5-4. インスタンスタイプ

- **インスタンスタイプ**: t3.micro（無料枠対象）

### 5-5. キーペア

- **キーペア名**: `commitly-key`（先ほど作成したもの）

### 5-6. ネットワーク設定

- **VPC**: デフォルト VPC
- **サブネット**: 指定なし（デフォルト）
- **パブリック IP の自動割り当て**: ✅ 有効
- **ファイアウォール（セキュリティグループ）**: 既存のセキュリティグループを選択 → `commitly-web-sg`

### 5-7. ストレージ設定

- **ボリュームサイズ**: 30 GB（無料枠は 30GB まで）
- **ボリュームタイプ**: gp3

### 5-8. インスタンスを起動

「インスタンスを起動」をクリック

### 5-9. Elastic IP 割り当て（固定 IP）

EC2 → 左メニュー「Elastic IP」→「Elastic IP アドレスを割り当てる」

- **ネットワーク境界グループ**: ap-northeast-1
- 「割り当て」をクリック

作成された Elastic IP を選択 → 「アクション」→「Elastic IP アドレスの関連付け」

- **リソースタイプ**: インスタンス
- **インスタンス**: `commitly-web`
- 「関連付け」をクリック

**Elastic IP をメモ**（例: `54.xxx.xxx.xxx`）

---

## ステップ 6: EC2 に Docker インストール（10分）

### 6-1. SSH 接続

```bash
ssh -i ~/.ssh/commitly-key.pem ubuntu@<Elastic IP>
# 例: ssh -i ~/.ssh/commitly-key.pem ubuntu@54.xxx.xxx.xxx
```

最初の接続時に「Are you sure you want to continue connecting?」→ `yes`

### 6-2. システムアップデート

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### 6-3. Docker インストール

```bash
# Docker の公式 GPG キー追加
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Docker リポジトリ追加
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker インストール
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ubuntu ユーザーを docker グループに追加
sudo usermod -aG docker ubuntu

# 一度ログアウト & ログイン（グループ変更を反映）
exit
```

再度 SSH 接続:
```bash
ssh -i ~/.ssh/commitly-key.pem ubuntu@<Elastic IP>
```

Docker 動作確認:
```bash
docker --version
# Docker version 27.x.x が表示されれば OK
```

### 6-4. Docker レジストリ認証設定（後で使用）

ローカルの Docker Hub アカウントを使う場合:

```bash
# EC2 上で実行
docker login
# Username: <Docker Hub ユーザー名>
# Password: <Docker Hub パスワード or アクセストークン>
```

---

## ステップ 7: ローカルで Kamal 設定（15分）

### 7-1. master.key 生成

```bash
# ローカルで実行
cd /Users/tomo/ghq/github.com.main/Tomo-akm/commitly

# master.key を生成
docker compose exec web rails credentials:edit
# エディタが開くので、何も変更せず保存して閉じる
# これで config/master.key が生成される
```

`config/master.key` が作成されたことを確認:
```bash
cat config/master.key
# 32文字の英数字が表示されれば OK
```

### 7-2. deploy.yml 更新

`config/deploy.yml` を編集:

```yaml
# Name of your application. Used to uniquely configure containers.
service: commitly

# Name of the container image.
image: <あなたのDockerHubユーザー名>/commitly
# 例: image: tomo-akm/commitly

# Deploy to these servers.
servers:
  web:
    - <EC2のElastic IP>
    # 例: - 54.xxx.xxx.xxx

# Credentials for your image host.
registry:
  username: <あなたのDockerHubユーザー名>
  password:
    - KAMAL_REGISTRY_PASSWORD

# Inject ENV variables into containers (secrets come from .kamal/secrets).
env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
  clear:
    SOLID_QUEUE_IN_PUMA: true
    RAILS_LOG_LEVEL: info

# Use a persistent storage volume.
volumes:
  - "commitly_storage:/rails/storage"

# Bridge fingerprinted assets.
asset_path: /rails/public/assets

# Configure the image builder.
builder:
  arch: amd64
```

### 7-3. .kamal/secrets 更新

`.kamal/secrets` を編集:

```bash
# Docker Hub のアクセストークン（または環境変数から取得）
# https://hub.docker.com/settings/security でトークン作成
KAMAL_REGISTRY_PASSWORD=<DockerHubアクセストークン>

# Rails マスターキー
RAILS_MASTER_KEY=$(cat config/master.key)

# データベース URL（RDS のエンドポイント情報）
# フォーマット: postgresql://ユーザー名:パスワード@エンドポイント:5432/データベース名
DATABASE_URL=postgresql://postgres:<RDSパスワード>@<RDSエンドポイント>:5432/commitly_production
# 例: DATABASE_URL=postgresql://postgres:YourStrongPassword@commitly-db.xxxxxx.ap-northeast-1.rds.amazonaws.com:5432/commitly_production
```

### 7-4. SSH 設定

ローカルの `~/.ssh/config` に追加:

```
Host commitly-web
  HostName <EC2のElastic IP>
  User ubuntu
  IdentityFile ~/.ssh/commitly-key.pem
```

SSH 接続テスト:
```bash
ssh commitly-web
# 接続できれば OK
exit
```

---

## ステップ 8: Kamal でデプロイ（20分）

### 8-1. Kamal インストール（ローカル）

```bash
gem install kamal
kamal version
# Kamal 2.x.x が表示されれば OK
```

### 8-2. 初回セットアップ

```bash
# ローカルで実行
cd /Users/tomo/ghq/github.com.main/Tomo-akm/commitly

# Kamal の初期設定（Docker インストール、ディレクトリ作成など）
kamal setup
```

**所要時間**: 約 10〜15 分

処理内容:
1. EC2 に SSH 接続
2. 必要なディレクトリ作成
3. Docker イメージのビルド & プッシュ（Docker Hub へ）
4. EC2 で Docker イメージをプル
5. コンテナ起動
6. ヘルスチェック

### 8-3. データベース初期化

```bash
# EC2 上で Rails コンソールを実行
kamal app exec "bin/rails db:migrate"
```

### 8-4. 動作確認

ブラウザで以下にアクセス:
```
http://<EC2のElastic IP>
```

Rails のトップページが表示されれば成功！

---

## ステップ 9: SSL 証明書設定（オプション、30分）

独自ドメインがある場合、Let's Encrypt で無料 SSL 証明書を取得できます。

### 9-1. ドメイン設定

Route 53 または他の DNS プロバイダーで A レコードを設定:
- `app.example.com` → `<EC2のElastic IP>`

### 9-2. Traefik プロキシ設定（Kamal 組み込み）

`config/deploy.yml` に追加:

```yaml
proxy:
  ssl: true
  host: app.example.com
```

### 9-3. 再デプロイ

```bash
kamal deploy
```

Kamal が自動的に:
1. Traefik プロキシをセットアップ
2. Let's Encrypt で SSL 証明書を取得
3. HTTPS リダイレクトを設定

`https://app.example.com` でアクセス可能になります。

---

## ステップ 10: 日常的なデプロイ

コードを更新したら:

```bash
# ローカルで実行
git add .
git commit -m "feat: 新機能追加"
kamal deploy
```

Kamal が自動的に:
1. Docker イメージをビルド
2. Docker Hub にプッシュ
3. EC2 で新しいイメージをプル
4. ゼロダウンタイムでコンテナを入れ替え

---

## トラブルシューティング

### デプロイが失敗する

```bash
# ログ確認
kamal app logs

# コンテナの状態確認
kamal app details
```

### データベース接続エラー

RDS セキュリティグループを確認:
- `commitly-db-sg` のインバウンドルールに `commitly-web-sg` が設定されているか

EC2 から RDS への接続テスト:
```bash
ssh commitly-web
docker run --rm postgres:16 psql $DATABASE_URL -c "SELECT 1"
# "1" が表示されれば接続 OK
```

### SSH 接続エラー

```bash
# キーペアの権限確認
chmod 400 ~/.ssh/commitly-key.pem

# セキュリティグループ確認
# commitly-web-sg のインバウンドルールに SSH (22) が「マイIP」で許可されているか
```

---

## コスト管理

### 無料枠の確認

AWS Billing → 請求ダッシュボード → 無料利用枠

確認項目:
- EC2: 750 時間/月（1 インスタンス常時起動で OK）
- RDS: 750 時間/月 + 20GB ストレージ

### 使わない時はインスタンスを停止

```bash
# EC2 コンソールからインスタンスを停止
# RDS コンソールからデータベースを停止（最大7日間）
```

**注意**: Elastic IP は EC2 停止中も課金されます（月 $3.6）
→ 長期間停止する場合は Elastic IP を解放

---

## 次のステップ

現在の構成が安定したら:

1. **CloudWatch でモニタリング**: CPU、メモリ、ディスク使用率を監視
2. **Auto Scaling 設定**: トラフィック増加時に自動スケール
3. **S3 で Active Storage**: ファイルアップロードを S3 に保存
4. **CloudFront 追加**: CDN で静的ファイル配信を高速化

---

## まとめ

これで最小構成での AWS デプロイが完了しました！

**コスト**: 初年度 $1〜3/月（無料枠内）
**パフォーマンス**: 小規模アプリには十分
**スケーラビリティ**: 成長に応じて段階的にアップグレード可能

質問があれば Claude に聞いてください！