# ☁️ Terraform GCP Blueprint

[![CI](https://github.com/mugipan-en/terraform-gcp-blueprint/actions/workflows/ci.yml/badge.svg)](https://github.com/mugipan-en/terraform-gcp-blueprint/actions/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4.svg)](https://www.terraform.io/)
[![GCP](https://img.shields.io/badge/GCP-Compatible-4285F4.svg)](https://cloud.google.com/)
[![Security](https://img.shields.io/badge/Security-tfsec%20%7C%20tflint-green.svg)](https://github.com/aquasecurity/tfsec)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Enterprise-grade Terraform modules for Google Cloud Platform with 20+ services and multi-environment support**

プロダクション対応のGCPインフラを短時間で構築。20のサービスモジュール、包括的ドキュメント、既存リソース移行ガイド付き。

## 🏗️ アーキテクチャ

```
environments/
├── dev/          # 開発環境
├── staging/      # ステージング環境
└── production/   # 本番環境

modules/                      # 20の包括的サービスモジュール
├── vpc/                    # VPC・ネットワーク
├── gke/                    # Google Kubernetes Engine
├── cloud-run/              # Cloud Run サーバーレスコンテナ
├── cloud-sql/              # Cloud SQL データベース
├── storage/                # Cloud Storage オブジェクトストレージ
├── monitoring/             # Cloud Monitoring・Logging
├── security/               # IAM・Secret Manager・KMS
├── load-balancer/          # Cloud Load Balancing・CDN
├── memorystore/            # Redis・Memcached キャッシュ
├── pubsub/                 # Cloud Pub/Sub メッセージング
├── cloud-functions/        # Cloud Functions サーバーレス関数
├── bigquery/               # BigQuery データウェアハウス
├── cloud-dns/              # Cloud DNS ドメイン管理
├── app-engine/             # App Engine Webアプリケーション
├── cloud-endpoints/        # Cloud Endpoints API管理
├── cloud-tasks/            # Cloud Tasks 非同期処理
├── cloud-firestore/        # Cloud Firestore NoSQLデータベース
├── cloud-spanner/          # Cloud Spanner 分散SQLデータベース
├── cloud-build/            # Cloud Build CI/CD
└── artifact-registry/      # Artifact Registry コンテナ・パッケージ管理
```

## 🚀 クイックスタート

### 1. 前提条件

```bash
# tenv (Terraform version manager) - 推奨
brew install tenv
tenv tf install 1.5.7
tenv tf use 1.5.7

# その他の必要なツール
brew install terragrunt tflint tfsec

# または直接インストール
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

### 2. GCP認証設定

```bash
# サービスアカウントキーでの認証
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"

# または gcloud CLI での認証
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 3. 環境構築

```bash
# リポジトリをクローン
git clone https://github.com/mugipan-en/terraform-gcp-blueprint.git
cd terraform-gcp-blueprint

# 開発環境を構築
make plan-dev
make apply-dev

# ステージング環境を構築
make plan-staging
make apply-staging
```

## 📋 主な機能

### 🌐 **ネットワーキング & セキュリティ**
- **VPC**: マルチリージョン対応のセキュアVPC・サブネット分離
- **Load Balancer**: Cloud Armor統合、SSL終端、CDN対応
- **Cloud DNS**: ドメイン管理・プライベートDNS・DNSSEC
- **IAM**: 最小権限アクセス制御・サービスアカウント管理
- **Secret Manager**: 機密情報の安全な管理・自動ローテーション
- **Cloud KMS**: 暗号化キー管理・HSM対応

### 🚀 **コンピューティング & サーバーレス**
- **GKE**: オートスケーリング・Workload Identity・プライベートクラスター
- **Cloud Run**: サーバーレスコンテナ・VPC統合・トラフィック分割
- **App Engine**: Standard/Flexible環境・Blue/Greenデプロイ
- **Cloud Functions**: Gen1/Gen2対応・イベントドリブン・VPC統合

### 🗄️ **データベース & ストレージ**
- **Cloud SQL**: HA構成・読み取りレプリカ・自動バックアップ
- **Cloud Firestore**: リアルタイム同期・セキュリティルール・インデックス管理
- **Cloud Spanner**: グローバル分散SQL・無制限スケーリング・ACID保証
- **BigQuery**: データウェアハウス・ML統合・ストリーミング分析
- **Cloud Storage**: ライフサイクル管理・マルチリージョン・暗号化
- **Memorystore**: Redis/Memcached・高可用性・自動フェイルオーバー

### 🔧 **DevOps & 統合**
- **Cloud Build**: CI/CDパイプライン・GitHub統合・並列ビルド
- **Artifact Registry**: コンテナ・パッケージ管理・脆弱性スキャン
- **Cloud Endpoints**: API管理・認証・レート制限・監視
- **Cloud Tasks**: 非同期処理・リトライポリシー・レート制御
- **Cloud Pub/Sub**: メッセージング・イベントドリブン・デッドレターキュー

### 📊 **監視・運用**
- **Cloud Monitoring**: メトリクス・アラート・ダッシュボード・SLI/SLO
- **Cloud Logging**: 構造化ログ・BigQueryエクスポート・リアルタイム分析

## 🔧 使用方法

### Makefileコマンド

```bash
# 環境別操作
make plan-dev          # 開発環境のプラン確認
make apply-dev         # 開発環境をデプロイ
make destroy-dev       # 開発環境を削除

make plan-staging      # ステージング環境のプラン確認
make apply-staging     # ステージング環境をデプロイ

make plan-production   # 本番環境のプラン確認
make apply-production  # 本番環境をデプロイ

# コード品質
make fmt              # Terraformコードフォーマット
make lint             # 静的解析 (tflint)
make security         # セキュリティスキャン (tfsec)
make validate         # 構文チェック
make docs             # ドキュメント生成

# ユーティリティ
make clean            # 一時ファイル削除
make init-all         # 全環境でterraform init
```

### 手動実行

```bash
# 特定の環境での作業
cd environments/dev
terraform init
terraform plan
terraform apply

# モジュール単体での作業
cd modules/vpc
terraform init
terraform plan -var-file="../../environments/dev/terraform.tfvars"
```

## 📁 ディレクトリ構成

```
terraform-gcp-blueprint/
├── environments/           # 環境別設定
│   ├── dev/
│   │   ├── main.tf        # メインリソース定義
│   │   ├── variables.tf   # 変数定義
│   │   ├── outputs.tf     # 出力値
│   │   ├── terraform.tfvars # 環境固有の値
│   │   └── versions.tf    # プロバイダーバージョン
│   ├── staging/
│   └── production/
├── modules/               # 再利用可能モジュール
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── gke/
│   ├── cloud-run/
│   ├── cloud-sql/
│   └── monitoring/
├── scripts/              # ヘルパースクリプト
├── docs/                 # 包括的ドキュメント
│   └── gcp-resources-guide.md  # 1,600行超の詳細ガイド
├── .github/workflows/    # CI/CD
├── terragrunt.hcl       # Terragrunt設定
├── Makefile
└── README.md
```

## ⚙️ 環境設定

### `terraform.tfvars` 例

```hcl
# environments/dev/terraform.tfvars
project_id = "my-gcp-project-dev"
region     = "asia-northeast1"
zone       = "asia-northeast1-a"

# ネットワーク設定
vpc_name = "dev-vpc"
subnet_cidr = "10.0.0.0/24"

# GKE設定
gke_cluster_name = "dev-cluster"
gke_node_count   = 2
gke_machine_type = "e2-standard-2"

# Cloud SQL設定
db_name          = "dev-database"
db_instance_type = "db-f1-micro"

# タグ
tags = {
  Environment = "development"
  Project     = "my-project"
  Owner       = "devops-team"
}
```

## 🔐 セキュリティ設定

### サービスアカウント

```bash
# Terraform用サービスアカウント作成
gcloud iam service-accounts create terraform-sa \
    --description="Terraform automation service account" \
    --display-name="Terraform SA"

# 必要な権限を付与
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:terraform-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

# キーファイル作成
gcloud iam service-accounts keys create terraform-sa-key.json \
    --iam-account=terraform-sa@PROJECT_ID.iam.gserviceaccount.com
```

### State管理

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "environments/dev"
  }
}
```

## 🧪 テスト

```bash
# 構文チェック
make validate

# セキュリティチェック
make security

# プランの確認（差分なし）
make plan-dev

# インフラテスト (Terratest)
cd tests
go test -v
```

## 🚀 デプロイフロー

### 開発環境

```bash
# 1. プラン確認
make plan-dev

# 2. 適用
make apply-dev

# 3. 動作確認
make test-dev
```

### 本番環境

```bash
# 1. ステージングで検証
make plan-staging
make apply-staging
make test-staging

# 2. 本番デプロイ
make plan-production
# レビュー後
make apply-production
```

## 📊 コスト最適化

### 推奨インスタンスタイプ

| 環境 | GKE ノード | Cloud SQL | 月額概算 |
|------|------------|-----------|----------|
| Dev | e2-micro (1 node) | db-f1-micro | $50-100 |
| Staging | e2-small (2 nodes) | db-g1-small | $150-250 |
| Production | e2-standard-4 (3+ nodes) | db-n1-standard-2 | $500+ |

### コスト監視

```hcl
# Cloud Billing Budget
resource "google_billing_budget" "budget" {
  billing_account = var.billing_account
  display_name    = "${var.environment}-budget"
  
  budget_filter {
    projects = ["projects/${var.project_id}"]
  }
  
  amount {
    specified_amount {
      currency_code = "USD"
      units         = "100"
    }
  }
}
```

## 🤝 コントリビューション

1. フォーク
2. フィーチャーブランチ作成 (`git checkout -b feature/new-module`)
3. テスト実行 (`make test`)
4. コミット (`git commit -m 'Add new module'`)
5. プッシュ (`git push origin feature/new-module`)
6. Pull Request作成

### 開発ガイドライン

- モジュールは独立性を保つ
- 変数と出力値に適切な説明を追加
- セキュリティベストプラクティスに従う
- ドキュメントを更新

## 📄 ライセンス

MIT License. 詳細は [LICENSE](LICENSE) を参照。

## 🙏 謝辞

- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [Google Cloud Platform](https://cloud.google.com/) - クラウドプラットフォーム
- [Terragrunt](https://terragrunt.gruntwork.io/) - Terraform wrapper

---

**⭐ GCPでのインフラ自動化にご活用ください！**