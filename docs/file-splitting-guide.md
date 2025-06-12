# 🔥 File Splitting Guide - モダンなTerraformファイル構成

このドキュメントでは、terraform-gcp-blueprintで採用されているFile Splitting（ファイル分割）パターンについて説明します。

## 📁 ファイル分割の目的

### 1. **可読性の向上**
- 機能別にファイルを分割することで、コードの理解が容易
- 関連するリソースが同じファイルにまとまっている
- 大きなファイルを小さな論理的な単位に分割

### 2. **保守性の向上**
- 特定の機能の変更時に該当ファイルのみを修正
- コードレビューが容易
- チーム開発での競合を減少

### 3. **再利用性の向上**
- 機能別の独立性が高い
- テストしやすい構成
- 段階的なデプロイが可能

## 📊 分割戦略

### 🎯 分割の原則

| 原則 | 説明 | 例 |
|------|------|-----|
| **機能別分割** | 関連する機能をグループ化 | `cluster.tf`, `node-pools.tf` |
| **ライフサイクル別** | 作成・更新タイミングが同じ | `instance.tf`, `databases.tf` |
| **責任別分割** | 管理する責任者・チーム別 | `security.tf`, `monitoring.tf` |
| **依存関係別** | 依存関係の階層に応じて | `locals.tf` → `instance.tf` → `databases.tf` |

### 📋 標準ファイル構成

#### 基本ファイル（全モジュール共通）
```
module/
├── main.tf          # モジュールのエントリポイント
├── variables.tf     # 入力変数定義
├── outputs.tf       # 出力値定義
├── locals.tf        # ローカル値・環境設定
└── README.md        # モジュール説明
```

#### 拡張ファイル（複雑なモジュール）
```
module/
├── main.tf                 # エントリポイント
├── variables.tf            # 変数定義
├── outputs.tf              # 出力
├── locals.tf               # ローカル値
├── service-account.tf      # IAM・サービスアカウント
├── {primary-resource}.tf   # メインリソース
├── {secondary-resource}.tf # 付随リソース
├── security.tf             # セキュリティ設定
├── monitoring.tf           # 監視設定
└── README.md              # ドキュメント
```

## 🏗️ 実装例

### GKEモジュールの分割

```
modules/gke/
├── main.tf              # Terraformプロバイダー設定
├── variables.tf         # 変数定義（Modern Optional Variables）
├── outputs.tf           # 出力値
├── locals.tf            # 環境設定・ローカル値
├── service-account.tf   # GKEサービスアカウント・IAM
├── cluster.tf           # GKEクラスター設定
├── node-pools.tf        # ノードプール管理
└── README.md           # 利用方法
```

#### ファイル別の役割

**main.tf**
```hcl
# 🔥 GKE Module - Modern File Structure
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
```

**locals.tf**
```hcl
# 🔥 Smart Environment Configuration
locals {
  environment_defaults = {
    dev = { ... }
    staging = { ... }
    production = { ... }
  }
  
  cluster_config = merge(local.env_config, var.cluster_config)
}
```

**service-account.tf**
```hcl
# 🔥 GKE Service Account Management
resource "google_service_account" "gke_sa" { ... }
resource "google_project_iam_member" "gke_sa_roles" { ... }
```

### Cloud SQLモジュールの分割

```
modules/cloud-sql/
├── main.tf         # プロバイダー設定
├── variables.tf    # 変数定義
├── outputs.tf      # 出力値
├── locals.tf       # 環境設定・ローカル値
├── instance.tf     # Cloud SQLインスタンス・レプリカ
├── databases.tf    # データベース・ユーザー管理
├── secrets.tf      # Secret Manager統合
└── README.md       # 利用方法
```

## 🎨 ファイル命名規則

### 📝 命名パターン

| パターン | 説明 | 例 |
|----------|------|-----|
| `{resource}.tf` | 主要リソース | `cluster.tf`, `instance.tf` |
| `{function}.tf` | 機能別 | `security.tf`, `monitoring.tf` |
| `{component}.tf` | コンポーネント別 | `node-pools.tf`, `databases.tf` |
| `{integration}.tf` | 外部統合 | `secrets.tf`, `logging.tf` |

### 🔤 命名ガイドライン

1. **ケバブケース使用**: `node-pools.tf`, `service-account.tf`
2. **複数形を使用**: `databases.tf`, `instances.tf`
3. **機能を明確に**: `secrets.tf` > `sm.tf`
4. **標準ファイル名**: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`

## 🔧 実装ベストプラクティス

### 1. **依存関係の管理**

```hcl
# locals.tf - 設定値の計算
locals {
  service_account_email = var.create_sa ? google_service_account.sa[0].email : var.sa_email
}

# service-account.tf - サービスアカウント作成
resource "google_service_account" "sa" {
  count = var.create_sa ? 1 : 0
  # ...
}

# cluster.tf - クラスター作成（サービスアカウントに依存）
resource "google_container_cluster" "primary" {
  # ...
  depends_on = [google_service_account.sa]
}
```

### 2. **リソース間の参照**

```hcl
# instance.tf
resource "google_sql_database_instance" "main" {
  name = local.instance_name
  # ...
}

# databases.tf  
resource "google_sql_database" "main" {
  instance = google_sql_database_instance.main.name  # 他ファイルのリソースを参照
  # ...
}
```

### 3. **locals.tfの活用**

```hcl
# locals.tf
locals {
  # 環境ベースの設定
  env_config = local.environment_defaults[var.environment]
  
  # 最終設定値
  final_config = merge(local.env_config, var.user_config)
  
  # 計算値
  instance_name = "${var.name_prefix}-${local.final_config.name}"
  
  # 共通ラベル
  common_labels = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
  })
}
```

## 🔄 マイグレーション手順

### 既存モジュールの分割

#### 1. **分析フェーズ**
```bash
# 既存ファイルの分析
wc -l modules/*/main.tf              # ファイルサイズ確認
grep -c "resource" modules/*/main.tf # リソース数確認
```

#### 2. **計画フェーズ**
- 機能別グループ分け
- 依存関係の整理
- ファイル名の決定

#### 3. **実装フェーズ**
```bash
# バックアップ作成
cp modules/gke/main.tf modules/gke/main.tf.backup

# ファイル分割
# 1. locals.tf作成
# 2. service-account.tf作成  
# 3. cluster.tf作成
# 4. node-pools.tf作成
# 5. main.tf更新
```

#### 4. **検証フェーズ**
```bash
# 構文チェック
terraform validate

# プラン確認（差分なし）
terraform plan

# フォーマット確認
terraform fmt -check
```

## 📊 メトリクス・指標

### 分割の効果測定

| 指標 | 分割前 | 分割後 | 改善率 |
|------|--------|--------|--------|
| **ファイル行数** | 500+ | <200 | 60%削減 |
| **リソース数/ファイル** | 20+ | <10 | 50%削減 |
| **機能凝集度** | 低 | 高 | 向上 |
| **変更影響範囲** | 広い | 限定的 | 向上 |

### 品質指標

```bash
# ファイルサイズ分析
find modules -name "*.tf" -exec wc -l {} \; | sort -n

# 複雑度分析  
grep -c "resource\|data\|module" modules/*/main.tf

# 依存関係分析
grep -c "depends_on" modules/*/*.tf
```

## 🎯 チーム開発での活用

### 1. **担当者別分割**
```
modules/gke/
├── cluster.tf        # インフラチーム
├── security.tf       # セキュリティチーム  
├── monitoring.tf     # SREチーム
└── applications.tf   # アプリケーションチーム
```

### 2. **レビュープロセス**
- ファイル単位でのコードレビュー
- 機能別の専門家レビュー
- 変更影響の局所化

### 3. **デプロイ戦略**
```bash
# 段階的デプロイ
terraform apply -target=module.vpc                    # ネットワーク先行
terraform apply -target=module.security               # セキュリティ設定
terraform apply -target=module.gke.google_container_cluster.primary  # クラスター作成
terraform apply                                       # 全体適用
```

## 🚨 注意点・制限事項

### 1. **避けるべきパターン**
- **過度な分割**: 1ファイル1リソースは避ける
- **循環依存**: ファイル間の循環参照を避ける
- **重複設定**: 同じ設定を複数ファイルに書かない

### 2. **パフォーマンス考慮**
- ファイル数の上限（~20ファイル）
- 読み込み時間への影響
- Terraformの並列実行制限

### 3. **チーム規約**
- ファイル命名規則の統一
- 分割基準の明確化
- ドキュメント保守の責任

## 📚 参考情報

- [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [Terraform Module Best Practices](https://developer.hashicorp.com/terraform/tutorials/modules/module-create)
- [Google Cloud Terraform Best Practices](https://cloud.google.com/docs/terraform/best-practices)

---

File Splittingにより、モジュールの保守性・可読性・再利用性が大幅に向上し、チーム開発での生産性向上を実現できます。