# 🔥 Smart Environment Configuration

このディレクトリには、環境別の設定例が含まれています。Smart Environment Configurationにより、環境（dev/staging/production）に応じて最適な設定が自動的に適用されます。

## 📋 機能

### 🎯 自動最適化
- **開発環境**: コスト最適化、高速デプロイ、緩いセキュリティ
- **ステージング環境**: 本番類似、バランス取れた設定
- **本番環境**: 高可用性、強固なセキュリティ、パフォーマンス最適化

### 🛠️ 主な自動調整項目

| 設定項目 | 開発環境 | ステージング環境 | 本番環境 |
|----------|----------|------------------|----------|
| **GKE ノード数** | 1 (preemptible) | 2 (standard) | 3+ (regional) |
| **インスタンスタイプ** | e2-standard-2 | e2-standard-2 | e2-standard-4 |
| **可用性** | ZONAL | ZONAL | REGIONAL |
| **Cloud SQL** | db-f1-micro | db-g1-small | db-n1-standard-2 |
| **バックアップ** | 無効 | 14日保持 | 30日保持 |
| **SSL** | 任意 | 必須 | 必須 |
| **監視** | 基本 | 詳細 | 包括的 |
| **ネットワークポリシー** | 無効 | 有効 | 有効 |

## 🚀 使用方法

### 1. 基本的な使用方法

```bash
# 開発環境
terraform apply -var-file="examples/environment-configurations/dev.tfvars"

# ステージング環境
terraform apply -var-file="examples/environment-configurations/staging.tfvars"

# 本番環境
terraform apply -var-file="examples/environment-configurations/production.tfvars"
```

### 2. 設定のカスタマイズ

環境のデフォルト値は自動的に適用されますが、必要に応じて上書きできます：

```hcl
# dev.tfvars
environment = "dev"

# GKE設定：開発環境デフォルトを一部上書き
cluster_config = {
  name            = "my-dev-cluster"
  network         = "dev-vpc"
  subnetwork      = "dev-private-subnet"
  # その他の設定は環境デフォルトが自動適用される
}

# ノードプール：特定の設定のみ指定
node_pools = {
  default = {
    machine_type = "e2-standard-4"  # デフォルトのe2-standard-2を上書き
    # その他（preemptible=true、disk_size_gb=50等）は自動適用
  }
}
```

### 3. 環境間での一貫性

同じコードベースで全環境をデプロイ：

```bash
# プロジェクト構成
environments/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars -> ../../examples/environment-configurations/dev.tfvars
├── staging/
│   ├── main.tf
│   └── terraform.tfvars -> ../../examples/environment-configurations/staging.tfvars
└── production/
    ├── main.tf
    └── terraform.tfvars -> ../../examples/environment-configurations/production.tfvars
```

## 📊 設定例詳細

### 開発環境 (dev.tfvars)
- **目的**: 迅速な開発・テストサイクル
- **最適化**: コスト重視
- **特徴**: 
  - Preemptibleインスタンス使用
  - 最小リソース構成
  - セキュリティ設定緩和
  - バックアップ無効

### ステージング環境 (staging.tfvars)
- **目的**: 本番環境のシミュレーション
- **最適化**: 本番類似性とコストのバランス
- **特徴**:
  - 本番類似のHA構成
  - セキュリティポリシー有効
  - 監視・アラート設定
  - バックアップ有効

### 本番環境 (production.tfvars)
- **目的**: 本番サービス運用
- **最適化**: 可用性・性能・セキュリティ重視
- **特徴**:
  - リージョナル冗長構成
  - 強固なセキュリティ設定
  - 包括的監視・アラート
  - 長期バックアップ保持

## 🔧 高度な設定

### カスタム環境の追加

新しい環境を追加する場合：

1. `modules/common/environment-config.tf`に環境定義を追加
2. 対応する`.tfvars`ファイルを作成
3. `environment`変数のバリデーションを更新

```hcl
# modules/common/environment-config.tf
locals {
  global_environment_config = {
    dev = { ... }
    staging = { ... }
    production = { ... }
    # 新しい環境を追加
    testing = {
      use_preemptible_instances = true
      enable_deletion_protection = false
      # ... その他の設定
    }
  }
}
```

### 環境固有の値の取得

Terraformコード内で環境設定を参照：

```hcl
# 共通環境設定モジュールを使用
module "env_config" {
  source = "../../modules/common"
  environment = var.environment
}

# 環境設定を他のモジュールで使用
module "gke" {
  source = "../../modules/gke"
  
  # 環境設定を渡す
  environment = var.environment
  
  # 環境固有のリソースサイズを使用
  resource_sizing = module.env_config.resource_sizing
  network_config  = module.env_config.network_config
}
```

## 💡 ベストプラクティス

### 1. 段階的デプロイ
```bash
# 1. 開発環境でテスト
terraform apply -var-file="dev.tfvars"

# 2. ステージング環境で検証
terraform apply -var-file="staging.tfvars"

# 3. 本番環境にデプロイ
terraform apply -var-file="production.tfvars"
```

### 2. 設定の検証
```bash
# プラン実行前に設定確認
terraform plan -var-file="production.tfvars" -out=prod.plan
terraform show prod.plan | grep -A 5 -B 5 "environment"
```

### 3. コスト最適化
- 開発環境では`preemptible = true`を活用
- 未使用時は開発環境をシャットダウン
- ステージング環境は必要時のみ起動

### 4. セキュリティ
- 本番環境では最小権限の原則を適用
- 環境間でのネットワーク分離
- 機密情報はSecret Managerで管理

## 🔍 トラブルシューティング

### よくある問題

1. **環境設定が適用されない**
   ```bash
   # environment変数が正しく設定されているか確認
   terraform console
   > var.environment
   ```

2. **リソースサイズが期待と異なる**
   ```bash
   # 環境デフォルトを確認
   terraform console
   > local.environment_defaults[var.environment]
   ```

3. **権限エラー**
   ```bash
   # 環境別のIAM設定を確認
   gcloud projects get-iam-policy PROJECT_ID --format=json
   ```

## 📚 参考情報

- [Terraform Optional Variables](https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional)
- [GCP Best Practices](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations)
- [Terraform Environment Management](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration)