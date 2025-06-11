# 📋 Google Cloud Platform リソース詳細ガイド

このドキュメントでは、terraform-gcp-blueprintで使用するGCPリソースについて、各サービスの機能、設定項目、他サービスとの連携、コスト感を詳しく解説します。

## 目次

1. [ネットワーキング](#ネットワーキング)
2. [コンピューティング](#コンピューティング)
3. [データベース](#データベース)
4. [ストレージ](#ストレージ)
5. [監視・ロギング](#監視ロギング)
6. [セキュリティ](#セキュリティ)
7. [BigQuery](#bigquery)
8. [メッセージング・非同期処理](#メッセージング非同期処理)
9. [メモリストア・キャッシュ](#メモリストアキャッシュ)
10. [負荷分散・CDN](#負荷分散cdn)
11. [DNS・ドメイン管理](#dnsドメイン管理)
12. [Webアプリケーション・API](#webアプリケーションapi)
13. [DevOps・CI/CD](#devopscicd)
14. [コスト最適化](#コスト最適化)

---

## ネットワーキング

### VPC (Virtual Private Cloud)

#### 概要
GCPの基盤となるプライベートネットワーク環境。物理的にはGoogleのグローバルネットワーク上に構築されるソフトウェア定義ネットワーク。

#### 主な機能
- **グローバルリソース**: 単一のVPCで複数リージョンをカバー
- **サブネット分離**: public/privateサブネットによるセキュリティ層の分離
- **カスタムルーティング**: 柔軟なトラフィック制御
- **ファイアウォール**: ステートフルなパケットフィルタリング

#### 設定項目

| 項目 | 説明 | 推奨値 |
|------|------|---------|
| `auto_create_subnetworks` | 自動サブネット作成 | `false` (カスタムモード推奨) |
| `routing_mode` | ルーティングモード | `REGIONAL` (コスト最適化) |
| `ip_cidr_range` | IPアドレス範囲 | RFC1918準拠 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) |

#### 他サービスとの連携
- **GKE**: Pod/Service用のセカンダリIPレンジを提供
- **Cloud SQL**: プライベートサービスアクセス経由で接続
- **Cloud Run**: VPCコネクタ経由でアクセス
- **Load Balancer**: フロントエンドIPとバックエンドインスタンスを接続

#### コスト
- VPC自体は無料
- Cloud NAT: $0.045/時間 + データ処理料金
- VPC Flow Logs: $0.50/GB
- ファイアウォールルール: 無料（1000ルールまで）

### Cloud NAT

#### 概要
プライベートサブネット内のリソースがインターネットにアウトバウンド接続するためのマネージドNATサービス。

#### 主な機能
- **マネージドサービス**: インフラ管理不要
- **自動スケーリング**: トラフィック量に応じた自動調整
- **ログ機能**: 接続ログの出力

#### 設定項目
- `nat_ip_allocate_option`: IP割り当て方式（AUTO_ONLY推奨）
- `source_subnetwork_ip_ranges_to_nat`: NAT対象範囲

#### コスト
- 基本料金: $0.045/時間
- データ処理: $0.045/GB

---

## コンピューティング

### GKE (Google Kubernetes Engine)

#### 概要
フルマネージドなKubernetesサービス。コンテナオーケストレーションを提供し、アプリケーションのデプロイ、管理、スケーリングを自動化。

#### 主な機能
- **マネージドコントロールプレーン**: Kubernetesマスターの管理が不要
- **オートスケーリング**: ワークロードに応じたノード自動増減
- **セキュリティ**: Workload Identity、Binary Authorization対応
- **監視統合**: Cloud Monitoring/Loggingとの緊密な連携

#### クラスタ構成オプション

| 構成 | 説明 | 用途 | コスト |
|------|------|------|--------|
| Zonal | 単一ゾーン構成 | 開発・テスト | 低コスト |
| Regional | 複数ゾーン構成 | 本番環境 | 高可用性 |
| Private | プライベートノード | セキュリティ重視 | 中〜高コスト |
| Autopilot | フルマネージド | 運用簡素化 | ポッド単位課金 |

#### ノードプール設定

| 項目 | 説明 | 推奨値 |
|------|------|---------|
| `machine_type` | VMインスタンスタイプ | 本番: `e2-standard-4`, 開発: `e2-standard-2` |
| `disk_type` | ディスクタイプ | `pd-standard` (コスト重視), `pd-ssd` (性能重視) |
| `auto_repair` | 自動修復 | `true` |
| `auto_upgrade` | 自動アップグレード | `true` |
| `preemptible` | プリエンプティブル | 開発環境: `true`, 本番: `false` |

#### 他サービスとの連携
- **Cloud SQL**: Cloud SQL Proxyでセキュア接続
- **Cloud Storage**: CSI ドライバーでボリューム利用
- **Secret Manager**: SecretManagerCSI でシークレット取得
- **Cloud Monitoring**: 自動的にメトリクス送信

#### コスト（asia-northeast1）

| リソース | 開発環境 | ステージング | 本番環境 |
|----------|----------|-------------|----------|
| コントロールプレーン | $0.10/時間 | $0.10/時間 | $0.10/時間 |
| e2-standard-2 | $0.067/時間 | $0.067/時間 | - |
| e2-standard-4 | - | $0.134/時間 | $0.134/時間 |
| プリエンプティブル | $0.020/時間 | - | - |

### Cloud Run

#### 概要
サーバーレスなコンテナ実行環境。HTTPリクエストやイベントドリブンなワークロードに最適。

#### 主な機能
- **ゼロからのスケーリング**: トラフィックがない時はコスト0
- **自動スケーリング**: 同時接続数に応じた自動調整
- **Blue/Green デプロイ**: トラフィック分散による安全なデプロイ
- **VPC統合**: VPCコネクタ経由でプライベートリソースアクセス

#### 設定項目

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `cpu` | CPUリソース | `1000m` (1 vCPU) |
| `memory` | メモリリソース | `512Mi` - `4Gi` |
| `max_scale` | 最大インスタンス数 | 100-1000 |
| `concurrency` | 同時リクエスト数 | 80-100 |

#### 他サービスとの連携
- **Cloud Load Balancing**: グローバル負荷分散
- **Cloud SQL**: プライベートIP経由接続
- **Cloud Storage**: シームレスアクセス
- **Cloud Tasks**: 非同期タスク処理

#### コスト
- vCPU時間: $0.000024/vCPU秒
- メモリ時間: $0.0000025/GiB秒
- リクエスト: $0.0000004/リクエスト
- 無料枠: 月200万リクエスト、36万vCPU秒、72万GiB秒

### Cloud Functions

#### 概要
サーバーレスな関数実行環境。軽量なイベント処理やAPIエンドポイントに最適。Gen1とGen2の両方をサポート。

#### 主な機能
- **イベントドリブン**: Pub/Sub、Cloud Storage、HTTPトリガー対応
- **自動スケーリング**: 需要に応じた瞬時のスケーリング
- **マルチランタイム**: Node.js、Python、Go、Java等をサポート
- **VPC統合**: プライベートリソースへのセキュアアクセス

#### Gen1 vs Gen2 比較

| 機能 | Gen1 | Gen2 |
|------|------|------|
| 最大実行時間 | 9分 | 60分 |
| 最大メモリ | 8GB | 32GB |
| 並行実行数 | 1000 | 1000 |
| コールドスタート | やや遅い | 高速 |
| 推奨用途 | 軽量処理 | 重い処理、長時間実行 |

#### 設定項目

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `runtime` | 実行環境 | `python39`, `nodejs18`, `go119` |
| `available_memory` | メモリ割り当て | `256MB` - `8GB` |
| `timeout_seconds` | タイムアウト | 60-540秒 |
| `max_instance_count` | 最大インスタンス数 | 100-3000 |
| `ingress_settings` | 受信設定 | `ALLOW_ALL`, `ALLOW_INTERNAL_ONLY` |

#### トリガータイプ

| トリガー | 用途 | 実装例 |
|----------|------|--------|
| HTTP | RESTful API | Webhook、API Gateway |
| Pub/Sub | 非同期メッセージ処理 | データパイプライン、通知処理 |
| Cloud Storage | ファイル処理 | 画像リサイズ、ログ解析 |
| Cloud Scheduler | 定期実行 | バッチ処理、ヘルスチェック |
| Firestore | データベース変更 | リアルタイム通知、データ同期 |

#### 他サービスとの連携
- **Cloud Pub/Sub**: イベント駆動アーキテクチャの中核
- **Cloud Storage**: ファイルアップロード時の自動処理
- **Cloud SQL**: データベース操作とビジネスロジック実行
- **BigQuery**: データ変換とETL処理
- **Cloud Monitoring**: 自動メトリクス収集と監視

#### パフォーマンス最適化

| 手法 | 効果 | 実装方法 |
|------|------|----------|
| 接続プール | DB接続効率化 | グローバル変数で接続保持 |
| キャッシュ活用 | レスポンス高速化 | Memorystore Redis連携 |
| 同期実行 | 処理時間短縮 | 並列処理ライブラリ活用 |
| コールドスタート対策 | 初回実行高速化 | 最小デプロイメント設定 |

#### コスト

**Gen1料金**
- 実行時間: $0.0000004/GB秒
- リクエスト: $0.0000004/リクエスト
- 無料枠: 月200万リクエスト、40万GB秒

**Gen2料金**
- vCPU時間: $0.0000024/vCPU秒
- メモリ時間: $0.0000025/GiB秒
- リクエスト: $0.0000004/リクエスト
- 無料枠: 月200万リクエスト、36万vCPU秒

#### 主な機能
- **ゼロからのスケーリング**: トラフィックがない時はコスト0
- **自動スケーリング**: 同時接続数に応じた自動調整
- **Blue/Green デプロイ**: トラフィック分散による安全なデプロイ
- **VPC 統合**: VPCコネクタ経由でプライベートリソースアクセス

#### 設定項目

| 項目 | 説明 | 推奨値 |
|------|------|---------|
| `cpu` | CPUリソース | `1000m` (1 vCPU) |
| `memory` | メモリリソース | `512Mi` - `4Gi` |
| `max_scale` | 最大インスタンス数 | 100-1000 |
| `concurrency` | 同時リクエスト数 | 80-100 |

#### 他サービスとの連携
- **Cloud Load Balancing**: グローバル負荷分散
- **Cloud SQL**: プライベートIP経由接続
- **Cloud Storage**: シームレスアクセス
- **Cloud Tasks**: 非同期タスク処理

#### コスト
- vCPU時間: $0.000024/vCPU秒
- メモリ時間: $0.0000025/GiB秒
- リクエスト: $0.0000004/リクエスト
- 無料枠: 月200万リクエスト、36万vCPU秒、72万GiB秒

---

## データベース

### Cloud SQL

#### 概要
フルマネージドなリレーショナルデータベースサービス。MySQL、PostgreSQL、SQL Serverをサポート。

#### 主な機能
- **自動バックアップ**: ポイントインタイムリカバリ対応
- **高可用性**: リージョナル構成で99.95%の可用性
- **自動パッチ適用**: セキュリティアップデートの自動適用
- **読み取りレプリカ**: 読み取り性能の向上

#### データベースエンジン比較

| エンジン | 特徴 | 適用ケース | 最新バージョン |
|----------|------|-----------|----------------|
| PostgreSQL | 高機能、ACID準拠 | 複雑なアプリケーション、分析処理 | PostgreSQL 15 |
| MySQL | 高速、シンプル | Webアプリケーション、WordPress | MySQL 8.0 |
| SQL Server | Microsoft エコシステム | .NET アプリケーション | SQL Server 2019 |

#### インスタンスタイプ

| タイプ | vCPU | メモリ | 用途 | 月額（概算） |
|--------|------|--------|------|-------------|
| db-f1-micro | 0.6 | 0.6GB | 開発・テスト | $8 |
| db-g1-small | 0.5 | 1.7GB | 小規模本番 | $25 |
| db-n1-standard-1 | 1 | 3.75GB | 中規模本番 | $50 |
| db-n1-standard-4 | 4 | 15GB | 大規模本番 | $200 |

#### 設定項目

| 項目 | 説明 | 推奨値 |
|------|------|---------|
| `availability_type` | 可用性構成 | 本番: `REGIONAL`, 開発: `ZONAL` |
| `backup_enabled` | バックアップ有効化 | `true` |
| `binary_log_enabled` | バイナリログ | `true` (レプリケーション使用時) |
| `disk_autoresize` | ディスク自動拡張 | `true` |
| `require_ssl` | SSL強制 | `true` |

#### 他サービスとの連携
- **GKE**: Cloud SQL Proxy経由でセキュア接続
- **Cloud Run**: プライベートIP経由接続
- **Cloud Functions**: 同期・非同期処理でのデータアクセス
- **Cloud Monitoring**: 自動的にメトリクス収集

#### コスト最適化
- **プリエンプティブルインスタンス**: 開発環境で60%コスト削減
- **読み取りレプリカ**: 読み取りワークロードの分散
- **ディスクサイズ最適化**: 使用量に応じた適切なサイズ設定

---

## ストレージ

### Cloud Storage

#### 概要
オブジェクトストレージサービス。静的ファイル、バックアップ、データアーカイブに使用。

#### ストレージクラス比較

| クラス | 用途 | 最小保存期間 | 取得料金 | 月額/GB |
|--------|------|-------------|----------|---------|
| Standard | 頻繁アクセス | なし | 無料 | $0.020 |
| Nearline | 月1回程度 | 30日 | $0.010/GB | $0.010 |
| Coldline | 四半期1回程度 | 90日 | $0.025/GB | $0.004 |
| Archive | 年1回程度 | 365日 | $0.050/GB | $0.0012 |

#### 主な機能
- **グローバル分散**: 世界中からの高速アクセス
- **ライフサイクル管理**: 自動的なストレージクラス移行
- **バージョニング**: オブジェクトの世代管理
- **暗号化**: 保存時・転送時の自動暗号化

#### 設定項目

| 項目 | 説明 | 推奨設定 |
|------|------|----------|
| `uniform_bucket_level_access` | 統一バケットレベルアクセス | `true` (セキュリティ強化) |
| `public_access_prevention` | パブリックアクセス防止 | `enforced` |
| `versioning` | バージョニング | 重要データ: `true` |
| `lifecycle_rule` | ライフサイクルルール | コスト最適化のため設定 |

#### 他サービスとの連携
- **BigQuery**: データレイクとしてシームレス連携
- **Cloud Functions**: イベントトリガーでの自動処理
- **Cloud Run**: 静的ファイル配信
- **Transfer Service**: 他クラウドからのデータ移行

#### セキュリティ設定
- **IAM**: きめ細かい権限制御
- **Signed URL**: 一時的アクセス許可
- **CORS**: ブラウザからの安全なアクセス
- **Customer-managed encryption**: 独自暗号化キー使用

---

## 監視・ロギング

### Cloud Monitoring

#### 概要
GCPリソースの包括的な監視サービス。メトリクス収集、アラート、ダッシュボードを提供。

#### 主な機能
- **自動的メトリクス収集**: GCPサービスから自動収集
- **カスタムメトリクス**: アプリケーション固有の監視
- **アラートポリシー**: 条件に基づく通知
- **Uptime監視**: エンドポイントの可用性監視

#### メトリクス種類

| 種類 | 説明 | 例 |
|------|------|-----|
| インフラメトリクス | リソース使用状況 | CPU、メモリ、ディスク |
| アプリケーションメトリクス | アプリケーション性能 | レスポンス時間、エラー率 |
| ビジネスメトリクス | ビジネス指標 | アクティブユーザー数、売上 |
| SLIメトリクス | サービスレベル指標 | 可用性、レイテンシ |

#### アラート設定

| 項目 | 説明 | 推奨設定 |
|------|------|----------|
| `threshold_value` | 閾値 | 段階的設定（警告80%、危険90%） |
| `duration` | 継続時間 | 5-10分（誤検知防止） |
| `notification_channels` | 通知先 | Email、Slack、PagerDuty |

#### 通知チャネル

| 種類 | 用途 | 設定例 |
|------|------|--------|
| Email | 一般的な通知 | チーム配布リスト |
| Slack | リアルタイム通知 | #alerts チャネル |
| PagerDuty | 緊急時対応 | オンコール担当者 |
| Webhook | カスタム統合 | 社内システム連携 |

### Cloud Logging

#### 概要
ログの収集、保存、分析、監視を行うサービス。

#### 主な機能
- **自動ログ収集**: GCPサービスから自動収集
- **構造化ログ**: JSON形式での効率的な検索
- **ログベースメトリクス**: ログからのメトリクス抽出
- **長期保存**: BigQueryへのエクスポート

#### ログ保持期間

| ログタイプ | デフォルト保持期間 | 推奨設定 |
|-----------|------------------|----------|
| Admin Activity | 400日 | そのまま |
| Data Access | 30日 | 90日以上（セキュリティ要件による） |
| System Event | 400日 | そのまま |
| アプリケーションログ | 30日 | 用途に応じて調整 |

---

## セキュリティ

### IAM (Identity and Access Management)

#### 概要
GCPリソースへのアクセス制御を管理するサービス。

#### 主要コンセプト
- **プリンシパル**: アクセス主体（ユーザー、サービスアカウントなど）
- **ロール**: 権限の集合
- **ポリシー**: プリンシパルとロールの関連付け
- **条件**: 細かいアクセス制御条件

#### ロール種類

| 種類 | 説明 | 使用例 |
|------|------|--------|
| 基本ロール | 粗い権限レベル | Viewer、Editor、Owner |
| 事前定義ロール | サービス特化権限 | Compute Admin、Storage Object Admin |
| カスタムロール | 独自権限セット | 最小権限の原則に基づく |

#### セキュリティベストプラクティス

| 項目 | 推奨事項 |
|------|----------|
| **最小権限の原則** | 必要最小限の権限のみ付与 |
| **ロール分離** | 職務に応じた適切なロール設計 |
| **定期的な権限監査** | 不要な権限の定期的な削除 |
| **サービスアカウント管理** | 用途別のサービスアカウント作成 |
| **条件付きアクセス** | IP制限、時間制限の活用 |

### Secret Manager

#### 概要
API キー、パスワード、証明書などの機密情報を安全に管理するサービス。

#### 主な機能
- **暗号化保存**: Google管理またはユーザー管理キーでの暗号化
- **バージョン管理**: シークレットの世代管理
- **自動ローテーション**: 定期的なシークレット更新
- **監査ログ**: アクセス履歴の記録

#### 設定項目

| 項目 | 説明 | 推奨設定 |
|------|------|----------|
| `replication` | レプリケーション設定 | `automatic` (高可用性) |
| `rotation` | 自動ローテーション | 重要なシークレット: 有効 |
| `labels` | ラベル | 管理目的での分類 |

#### 他サービスとの連携
- **GKE**: SecretManagerCSI でポッド内アクセス
- **Cloud Run**: 環境変数での安全な注入
- **Cloud Functions**: 実行時でのシークレット取得

### Cloud KMS

#### 概要
暗号化キーの管理サービス。データの暗号化・復号化を統一的に管理。

#### キータイプ

| タイプ | 説明 | 用途 |
|--------|------|------|
| 対称キー | 暗号化・復号化に同じキー | データ暗号化 |
| 非対称キー | 公開キー・秘密キーペア | デジタル署名、TLS |
| MAC キー | メッセージ認証コード | データ整合性検証 |

#### 保護レベル

| レベル | 説明 | セキュリティレベル | コスト |
|--------|------|------------------|--------|
| SOFTWARE | ソフトウェア保護 | 標準 | 低 |
| HSM | Hardware Security Module | 高 | 高 |

---

## BigQuery

### 概要
サーバーレスなデータウェアハウスサービス。ペタバイト規模のデータ分析が可能。

### 主な機能
- **サーバーレス**: インフラ管理不要
- **超高速SQL**: 大規模データの高速クエリ
- **ML統合**: BigQuery ML でのモデル作成
- **リアルタイム分析**: ストリーミングデータの即座分析

### データセット・テーブル構成

| 項目 | 説明 | 推奨設定 |
|------|------|----------|
| `location` | データロケーション | `asia-northeast1` (レイテンシ最適化) |
| `partition` | パーティション設定 | 日付カラムでのパーティション |
| `clustering` | クラスタリング | よく使用するカラムで設定 |
| `expiration` | データ有効期限 | コスト最適化のため設定 |

### 他サービスとの連携

| サービス | 連携方法 | 用途 |
|----------|----------|------|
| Cloud Storage | 外部テーブル、データ読み込み | データレイク統合 |
| Cloud Logging | ログエクスポート | ログ分析 |
| Cloud Monitoring | メトリクスエクスポート | 長期監視データ保存 |
| Cloud Pub/Sub | ストリーミング取り込み | リアルタイム分析 |
| Data Studio | 可視化 | ダッシュボード作成 |

### コスト構造

| 項目 | 料金 | 最適化方法 |
|------|------|-----------|
| ストレージ | $0.020/GB/月 | パーティション、クラスタリング |
| クエリ処理 | $5.00/TB | SELECT文の最適化 |
| ストリーミング | $0.010/200MB | バッチ処理の活用 |
| スロット予約 | $2000/月〜 | 定期的な大量処理向け |

### クエリ最適化

| 手法 | 効果 | 実装例 |
|------|------|--------|
| カラム選択 | スキャン量削減 | `SELECT id, name` の代わりに `SELECT *` を避ける |
| WHERE句フィルタ | 処理データ削減 | パーティションカラムでの絞り込み |
| JOIN最適化 | 処理時間短縮 | 小さいテーブルを右側に配置 |
| 集約前フィルタ | メモリ使用量削減 | GROUP BY前にWHERE句 |

---

## メッセージング・非同期処理

### Cloud Pub/Sub

#### 概要
スケーラブルなメッセージングサービス。リアルタイムな非同期通信とイベント駆動アーキテクチャを実現。

#### 主な機能
- **At-Least-Once配信**: メッセージ配信保証
- **順序付き配信**: FIFO配信のサポート
- **グローバル配信**: 世界中への低レイテンシ配信
- **デッドレターキュー**: 失敗メッセージの自動処理

#### アーキテクチャパターン

| パターン | 説明 | 用途 |
|----------|------|------|
| Fan-out | 1つのトピックから複数のサブスクリプション | 通知配信、ログ配信 |
| Work Queue | 複数のワーカーでタスク分散処理 | バッチ処理、画像処理 |
| Request-Reply | 同期的なメッセージ交換 | マイクロサービス間通信 |
| Event Streaming | 連続的なイベント処理 | リアルタイム分析 |

#### 設定項目

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `message_retention_duration` | メッセージ保持期間 | `604800s` (7日) |
| `ack_deadline_seconds` | 確認応答期限 | `60s` |
| `enable_message_ordering` | 順序保証 | 必要に応じて `true` |
| `max_delivery_attempts` | 最大配信試行回数 | `5` |

#### 他サービスとの連携

| サービス | 連携方法 | 用途 |
|----------|----------|------|
| Cloud Functions | イベントトリガー | サーバーレス処理 |
| Cloud Run | Push配信 | コンテナベース処理 |
| BigQuery | サブスクリプションエクスポート | ストリーミング分析 |
| Cloud Storage | サブスクリプションエクスポート | データアーカイブ |
| Cloud Logging | ログエクスポート | 集中ログ管理 |

#### Pub/Sub Lite

| 項目 | 標準 Pub/Sub | Pub/Sub Lite |
|------|-------------|--------------|
| 料金体系 | スループット課金 | 容量事前予約 |
| スケーラビリティ | 無制限自動 | 手動調整 |
| 可用性 | 99.95% | 99.9% |
| 適用ケース | 一般的用途 | 大量データ、コスト重視 |

#### コスト

**標準 Pub/Sub**
- メッセージ配信: $0.040/100万メッセージ
- 存在しないサブスクリプション: $0.60/100万オペレーション
- 無料枠: 月10GBまで

**Pub/Sub Lite**
- パーティション予約: $0.40/月/パーティション
- ストレージ: $0.50/月/TiB
- スループット予約: $0.40/月/MiB/秒

---

## メモリストア・キャッシュ

### Memorystore

#### 概要
フルマネージドなインメモリデータストアサービス。RedisとMemcachedをサポートし、アプリケーションの高速化を実現。

#### Redis vs Memcached

| 機能 | Redis | Memcached |
|------|-------|-----------|
| データ構造 | 豊富（String、Hash、List等） | Key-Value のみ |
| 永続化 | RDB、AOF対応 | なし |
| レプリケーション | マスター・スレーブ | なし |
| クラスタリング | 対応 | 対応 |
| 用途 | セッション管理、キャッシュ、PubSub | シンプルキャッシュ |

#### Redis設定オプション

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `memory_size_gb` | メモリサイズ | 1-300GB（用途に応じて） |
| `tier` | サービス階層 | `STANDARD_HA`（本番）、`BASIC`（開発） |
| `redis_version` | Redisバージョン | `REDIS_6_X` |
| `auth_enabled` | 認証有効化 | `true` |
| `transit_encryption_mode` | 転送暗号化 | `SERVER_AUTH` |

#### 高可用性構成

| 構成 | 説明 | RTO | RPO |
|------|------|-----|-----|
| Basic | 単一ノード | 数分 | データ損失可能性あり |
| Standard HA | レプリカ付き | 数秒 | ほぼゼロ |
| Cluster | 分散クラスタ | 数秒 | ほぼゼロ |

#### 監視メトリクス

| メトリクス | 説明 | 閾値例 |
|-----------|------|--------|
| `memory_utilization` | メモリ使用率 | > 80% で警告 |
| `hit_ratio` | キャッシュヒット率 | < 90% で調査 |
| `connected_clients` | 接続クライアント数 | 上限値の80% |
| `operations_per_second` | 毎秒オペレーション数 | ベースライン比較 |

#### 他サービスとの連携
- **GKE**: アプリケーションキャッシュとセッション管理
- **Cloud Run**: ステートレスアプリケーションの状態保持
- **Cloud Functions**: 一時的なデータ保存と高速アクセス
- **Cloud SQL**: クエリ結果キャッシュによる性能向上

#### パフォーマンス最適化

| 手法 | 効果 | 実装方法 |
|------|------|----------|
| 接続プール | 接続オーバーヘッド削減 | アプリケーション側で実装 |
| パイプライン化 | レイテンシ削減 | 複数コマンドの一括送信 |
| 適切なデータ構造選択 | メモリ効率向上 | Hash vs String の使い分け |
| TTL設定 | メモリ使用量最適化 | データの生存期間設定 |

#### コスト

**Redis料金（asia-northeast1）**

| Tier | サイズ | 月額概算 |
|------|--------|----------|
| Basic | 1GB | $35 |
| Standard HA | 1GB | $80 |
| Standard HA | 5GB | $400 |
| Standard HA | 10GB | $800 |

**Memcached料金**
- CPU: $0.053/vCPU時間
- メモリ: $0.009/GB時間

---

## 負荷分散・CDN

### Cloud Load Balancing

#### 概要
グローバルまたはリージョナルな負荷分散サービス。HTTPSトラフィックの分散とSSL終端を提供。

#### ロードバランサータイプ

| タイプ | 範囲 | プロトコル | 用途 |
|--------|------|-----------|------|
| Global HTTP(S) | グローバル | HTTP/HTTPS | Webアプリケーション |
| Global SSL Proxy | グローバル | SSL/TCP | TCPアプリケーション |
| Regional Network | リージョナル | TCP/UDP | 内部トラフィック |
| Regional Internal | リージョナル | HTTP/HTTPS | マイクロサービス間 |

#### 主な機能
- **グローバル負荷分散**: 世界中の最適なバックエンドへルーティング
- **SSL終端**: SSL証明書の一元管理
- **Cloud CDN統合**: 静的コンテンツのエッジキャッシュ
- **Cloud Armor統合**: DDoS攻撃やセキュリティ脅威からの保護

#### SSL証明書管理

| タイプ | 管理方法 | 更新 | 適用ケース |
|--------|----------|------|-----------|
| Google管理 | 自動プロビジョニング | 自動 | 標準的なWebサイト |
| 自己管理 | 手動アップロード | 手動 | 社内CA、特殊要件 |
| Certificate Manager | API経由管理 | 自動 | 企業レベル管理 |

#### バックエンドサービス設定

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `balancing_mode` | 負荷分散モード | `UTILIZATION` |
| `capacity_scaler` | 容量調整係数 | `1.0` |
| `max_utilization` | 最大使用率 | `0.8` |
| `timeout_sec` | タイムアウト | `30` |

#### Cloud CDN設定

| 項目 | 説明 | 推奨設定 |
|------|------|----------|
| `cache_mode` | キャッシュモード | `CACHE_ALL_STATIC` |
| `default_ttl` | デフォルトTTL | `3600s` |
| `max_ttl` | 最大TTL | `86400s` |
| `negative_caching` | ネガティブキャッシュ | `true` |

#### Cloud Armor セキュリティポリシー

| ルール種類 | 説明 | 用途 |
|-----------|------|------|
| IP許可/拒否 | 送信元IP制御 | 地理的制限、悪意のあるIP |
| Rate Limiting | レート制限 | DDoS攻撃防止 |
| ModSecurity | WAF機能 | SQLインジェクション、XSS |
| Bot Management | ボット対策 | スクレイピング防止 |

#### 他サービスとの連携
- **GKE**: Ingress経由でのサービス公開
- **Cloud Run**: サーバーレスアプリケーションの負荷分散
- **Cloud Storage**: 静的サイトホスティング
- **Cloud Monitoring**: トラフィック監視とアラート

#### パフォーマンス最適化

| 手法 | 効果 | 実装方法 |
|------|------|----------|
| 適切なバックエンド配置 | レイテンシ削減 | 複数リージョンでのデプロイ |
| CDN活用 | 応答速度向上 | 静的コンテンツのキャッシュ |
| ヘルスチェック最適化 | 障害検出高速化 | 間隔とタイムアウトの調整 |
| セッション親和性 | ユーザー体験向上 | Cookie-based affinity |

#### コスト

**ロードバランサー基本料金**
- Global LB: $0.025/時間
- Regional LB: $0.015/時間

**処理料金**
- 最初の1GB/月: 無料
- 1-10TB: $0.008/GB
- 10TB以上: $0.004/GB

**SSL証明書**
- Google管理証明書: 無料
- 自己管理証明書: $0.75/月/証明書

---

## DNS・ドメイン管理

### Cloud DNS

#### 概要
高性能なマネージドDNSサービス。権威DNSサーバーとしてドメインの名前解決を提供。

#### 主な機能
- **高可用性**: 100%のSLA保証
- **グローバルエニーキャスト**: 世界中のDNSサーバーからの応答
- **DNSSEC対応**: DNS応答の真正性保証
- **Private DNS**: VPC内での内部名前解決

#### DNSゾーンタイプ

| タイプ | 説明 | 用途 |
|--------|------|------|
| Public Zone | インターネット向け | 外部ユーザーからのアクセス |
| Private Zone | VPC内限定 | 内部サービスの名前解決 |
| Forwarding Zone | 他DNSへ転送 | ハイブリッドクラウド環境 |
| Peering Zone | VPCピアリング | 複数VPC間の名前解決 |

#### サポートするレコードタイプ

| レコード | 用途 | 例 |
|----------|------|-----|
| A | IPv4アドレス | `example.com. → 192.168.1.1` |
| AAAA | IPv6アドレス | `example.com. → 2001:db8::1` |
| CNAME | 別名 | `www.example.com. → example.com.` |
| MX | メール交換 | `example.com. → 10 mail.example.com.` |
| TXT | テキスト情報 | SPF、DKIM、ドメイン認証 |
| SRV | サービス情報 | `_sip._tcp.example.com.` |

#### DNSSEC設定

| 項目 | 説明 | 推奨設定 |
|------|------|----------|
| `state` | DNSSEC状態 | `on` （セキュリティ重視時） |
| `non_existence` | 非存在証明 | `nsec3` |
| `algorithm` | 署名アルゴリズム | `rsasha256` |
| `key_length` | キー長 | `2048` |

#### DNS ポリシー

| 機能 | 説明 | 用途 |
|------|------|------|
| Inbound Forwarding | 外部からのDNSクエリ受信 | オンプレミスからの名前解決 |
| Alternative Name Servers | 代替ネームサーバー設定 | カスタムDNS設定 |
| DNS Logging | DNSクエリログ | セキュリティ監査、トラブルシューティング |

#### Response Policy (DNS Firewall)

| 機能 | 説明 | 用途 |
|------|------|------|
| ドメインブロッキング | 悪意のあるドメインへのアクセス防止 | セキュリティ強化 |
| カスタム応答 | 特定ドメインへのカスタム応答 | 内部リダイレクト |
| ログ出力 | ブロック/許可ログ | セキュリティ監査 |

#### 他サービスとの連携
- **Cloud Load Balancing**: ドメインとロードバランサーIPの関連付け
- **GKE**: ExternalDNSによるサービス自動登録
- **Certificate Manager**: SSL証明書の自動検証
- **Cloud Logging**: DNSクエリログの集中管理

#### パフォーマンス最適化

| 手法 | 効果 | 設定 |
|------|------|------|
| 適切なTTL設定 | キャッシュ効率向上 | A: 300s、CNAME: 3600s |
| レコード最適化 | 解決速度向上 | 不要なCNAMEチェーン削除 |
| ヘルスチェック連携 | 障害時自動切替 | ロードバランサー統合 |
| 地理的負荷分散 | レスポンス向上 | 複数リージョンでのA/CNAMEレコード |

#### コスト

**DNS ゾーン**
- パブリックゾーン: $0.20/月/ゾーン（最初の25ゾーンまで）
- プライベートゾーン: $0.10/月/ゾーン

**DNSクエリ**
- 最初の10億クエリ/月: $0.40/100万クエリ
- 10億超: $0.20/100万クエリ

**DNSSEC**
- 追加料金なし

---

## Webアプリケーション・API

### App Engine

#### 概要
Googleが提供するフルマネージドなサーバーレスプラットフォーム。スケーラブルなWebアプリケーションとAPIを簡単にデプロイ・運用。

#### 主な機能
- **自動スケーリング**: トラフィックに応じた瞬時のスケール
- **多言語対応**: Python、Node.js、Java、Go、PHP、Ruby対応
- **統合監視**: Cloud Monitoring/Loggingとの自動統合
- **バージョン管理**: Blue/Greenデプロイとトラフィック分割

#### Standard vs Flexible比較

| 項目 | Standard環境 | Flexible環境 |
|------|-------------|-------------|
| 起動時間 | ミリ秒 | 分単位 |
| スケール | ゼロから瞬時 | 最小1インスタンス |
| カスタマイズ | 制限あり | 自由度高 |
| コスト | インスタンス時間 | VM時間 |
| 用途 | Web UI、API | マイクロサービス、バッチ |

#### 環境設定

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `runtime` | 実行環境 | `python39`, `nodejs18` |
| `instance_class` | インスタンスクラス | Standard: `F1`, Flexible: `B1` |
| `automatic_scaling` | 自動スケーリング | 有効 |
| `max_instances` | 最大インスタンス数 | 10-100 |

#### トラフィック分割

| 方式 | 説明 | 用途 |
|------|------|------|
| IP分割 | IPアドレスベース | ユーザー固定 |
| Cookie分割 | Cookieベース | セッション継続 |
| Random分割 | ランダム | A/Bテスト |

#### 他サービスとの連携
- **Cloud SQL**: プライベート接続でのデータベースアクセス
- **Cloud Storage**: 静的ファイルとアプリケーション配信
- **Cloud Tasks**: 非同期処理の実行
- **Cloud Endpoints**: API管理と認証

#### コスト（asia-northeast1）

**Standard環境**
- F1インスタンス: $0.05/時間
- F2インスタンス: $0.10/時間
- F4インスタンス: $0.30/時間
- 無料枠: 月28時間

**Flexible環境**
- B1インスタンス: $0.056/時間
- B2インスタンス: $0.112/時間
- カスタム: vCPU + メモリ課金

### Cloud Endpoints

#### 概要
RESTful APIとgRPC APIを管理するAPIゲートウェイサービス。認証、監視、レート制限、分析を統合提供。

#### 主な機能
- **OpenAPI準拠**: Swagger/OpenAPI仕様書からの自動生成
- **gRPCサポート**: Protocol Buffers定義からの自動生成
- **認証・認可**: API Key、OAuth 2.0、JWT対応
- **監視・分析**: リアルタイムAPI使用状況監視

#### APIタイプ

| タイプ | プロトコル | 用途 | 設定方式 |
|--------|----------|------|----------|
| OpenAPI | REST/HTTP | Web API | swagger.yaml |
| gRPC | HTTP/2 | マイクロサービス | .proto + descriptor |
| App Engine | REST | App Engine連携 | 自動検出 |

#### 認証方式

| 方式 | セキュリティレベル | 実装難易度 | 用途 |
|------|------------------|------------|------|
| API Key | 低 | 簡単 | パブリックAPI |
| OAuth 2.0 | 高 | 中 | ユーザー認証 |
| JWT | 高 | 中 | サービス間認証 |
| Service Account | 最高 | 高 | 内部API |

#### 設定項目

| 項目 | 説明 | 推奨設定 |
|------|------|----------|
| `quota` | レート制限 | 1000req/min |
| `authentication` | 認証設定 | 用途に応じて |
| `cors` | CORS設定 | フロントエンド用途で有効 |
| `logging` | ログレベル | INFO以上 |

#### 他サービスとの連携
- **App Engine**: 自動的なAPI発見と管理
- **Cloud Run**: コンテナ化されたAPIサービス
- **GKE**: Kubernetesサービスメッシュ統合
- **Cloud Functions**: サーバーレスAPI実装

#### パフォーマンス最適化

| 手法 | 効果 | 実装方法 |
|------|------|----------|
| キャッシュ活用 | レスポンス高速化 | Cache-Controlヘッダー |
| 圧縮有効化 | 転送量削減 | gzip圧縮 |
| CDN統合 | グローバル配信 | Cloud CDN経由 |
| バッチ処理 | API呼び出し削減 | 複数操作の統合 |

#### コスト
- **API呼び出し**: $3.00/100万呼び出し
- **無料枠**: 月200万呼び出し
- **管理オーバーヘッド**: 無料

### Cloud Tasks

#### 概要
非同期タスク実行のためのフルマネージドキューサービス。信頼性の高いタスクディスパッチングを提供。

#### 主な機能
- **確実な配信**: At-least-once配信保証
- **リトライ機能**: 設定可能な再試行ポリシー
- **レート制限**: QPS制御とバーストサイズ管理
- **スケジューリング**: 遅延実行とスケジュール実行

#### キューの種類

| タイプ | ターゲット | 用途 |
|--------|----------|------|
| HTTP Queue | HTTPエンドポイント | 汎用タスク処理 |
| App Engine Queue | App Engineサービス | App Engine専用 |

#### 設定項目

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `max_dispatches_per_second` | 最大QPS | 500 |
| `max_concurrent_dispatches` | 最大並行数 | 1000 |
| `max_attempts` | 最大再試行回数 | 5 |
| `max_retry_duration` | 最大リトライ期間 | 1時間 |

#### タスクの種類

| パターン | 説明 | 実装例 |
|----------|------|--------|
| Fire-and-forget | 結果を待たない | メール送信、ログ処理 |
| Batch処理 | 大量データ処理 | CSVインポート、レポート生成 |
| Workflow | 複数ステップ処理 | 注文処理、承認フロー |
| Scheduled | 定期実行 | バックアップ、レポート配信 |

#### 他サービスとの連携
- **Cloud Functions**: HTTPトリガー経由でのタスク実行
- **Cloud Run**: スケーラブルなタスクワーカー
- **App Engine**: ネイティブ統合でのタスク処理
- **Pub/Sub**: イベント駆動との組み合わせ

#### エラーハンドリング

| 状況 | 対応 | 設定 |
|------|------|------|
| 一時的エラー | 指数バックオフ再試行 | `min_backoff` - `max_backoff` |
| 永続的エラー | デッドレターキュー | `max_attempts`後 |
| レート制限 | 配信速度調整 | `max_dispatches_per_second` |

#### コスト
- **タスク実行**: $0.40/100万タスク
- **無料枠**: 月100万タスク
- **ストレージ**: $0.01/GB/月

---

## データベース

### Cloud Firestore

#### 概要
NoSQLドキュメントデータベース。リアルタイム同期、オフライン対応、自動スケーリングを提供するモバイル・Web開発向けデータベース。

#### 主な機能
- **リアルタイム同期**: クライアント間でのデータ即座反映
- **オフライン対応**: ローカルキャッシュでのオフライン動作
- **ACID準拠**: 強一貫性トランザクション
- **グローバル分散**: 世界中の複数リージョンでの複製

#### データモデル

| 概念 | 説明 | 例 |
|------|------|-----|
| Document | JSONライクなデータ | `{ name: "John", age: 30 }` |
| Collection | ドキュメントのグループ | `/users` |
| Subcollection | ネストされたコレクション | `/users/john/orders` |
| Reference | 他ドキュメントへの参照 | DocumentReference |

#### Native vs Datastore比較

| 項目 | Firestore Native | Datastore Mode |
|------|-----------------|----------------|
| データモデル | ドキュメント指向 | エンティティベース |
| リアルタイム | 対応 | 非対応 |
| インデックス | 自動 + カスタム | カスタムのみ |
| SQL機能 | 制限あり | GQLサポート |
| 用途 | モバイル・Web | サーバーサイド |

#### インデックス戦略

| タイプ | 説明 | 用途 |
|--------|------|------|
| 単一フィールド | 1つのフィールド | 基本検索 |
| 複合インデックス | 複数フィールド | 複雑なクエリ |
| 配列インデックス | 配列要素 | 配列内検索 |
| マップインデックス | マップキー | ネストデータ検索 |

#### セキュリティルール例

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のドキュメントのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // パブリック読み取り、認証済みユーザーのみ書き込み
    match /posts/{postId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

#### 他サービスとの連携
- **Firebase Authentication**: ユーザー認証と連携
- **Cloud Functions**: データ変更トリガー
- **BigQuery**: データ分析のためのエクスポート
- **App Engine**: サーバーサイドアプリケーション

#### パフォーマンス最適化

| 手法 | 効果 | 実装方法 |
|------|------|----------|
| 適切なインデックス | クエリ高速化 | 複合インデックス設計 |
| データ非正規化 | 読み取り最適化 | 冗長だが高速なデータ構造 |
| バッチ処理 | 書き込み効率化 | batch() writeの活用 |
| ページネーション | メモリ効率化 | startAfter()での分割 |

#### コスト

**ストレージ**
- $0.18/GiB/月

**読み取り・書き込み**
- 読み取り: $0.036/10万ドキュメント
- 書き込み: $0.108/10万ドキュメント
- 削除: $0.012/10万ドキュメント

**無料枠（日次）**
- 読み取り: 50,000回
- 書き込み: 20,000回
- 削除: 20,000回
- ストレージ: 1GiB

### Cloud Spanner

#### 概要
水平分散可能なリレーショナルデータベース。グローバルな強一貫性と99.999%の可用性を提供。

#### 主な機能
- **グローバル分散**: 世界規模での強一貫性
- **水平スケーリング**: 無制限スケーリング
- **ACID準拠**: 完全なトランザクション保証
- **SQL互換**: 標準SQLサポート

#### アーキテクチャ

| 構成要素 | 説明 | 役割 |
|----------|------|------|
| Instance | 計算リソース | ノード集合の管理単位 |
| Database | データベース | スキーマとデータ |
| Node | 処理単位 | 2TBストレージ + 計算力 |
| Split | データ分割単位 | 自動分散の最小単位 |

#### インスタンス構成

| 構成 | ノード数 | 可用性 | 用途 |
|------|----------|--------|------|
| Single Region | 1-1000 | 99.99% | 単一地域 |
| Multi-Regional | 3-1000 | 99.999% | グローバル展開 |

#### パフォーマンス特性

| メトリクス | 目安値 | 説明 |
|-----------|--------|------|
| 読み取りレイテンシ | 1-7ms | リージョン内 |
| 書き込みレイテンシ | 5-10ms | グローバル合意 |
| スループット | 10K QPS/ノード | ノード当たり |
| ストレージ | 2TB/ノード | 最大容量 |

#### スキーマ設計ベストプラクティス

| 原則 | 説明 | 例 |
|------|------|-----|
| ホットスポット回避 | 単調増加キー避ける | UUID使用 |
| インターリーブテーブル | 親子関係最適化 | `INTERLEAVE IN PARENT` |
| セカンダリインデックス | クエリ最適化 | 検索フィールドのインデックス |
| 適切なデータ型 | 効率的ストレージ | `TIMESTAMP` vs `STRING` |

#### 他サービスとの連携
- **BigQuery**: データ分析のためのフェデレーション
- **Cloud Dataflow**: ETL処理
- **Cloud Functions**: イベント処理
- **GKE**: アプリケーションからの接続

#### 自動スケーリング設定

| 項目 | 説明 | 推奨値 |
|------|------|--------|
| `min_nodes` | 最小ノード数 | 1 |
| `max_nodes` | 最大ノード数 | 10 |
| `target_cpu_utilization` | 目標CPU使用率 | 65% |
| `target_storage_utilization` | 目標ストレージ使用率 | 75% |

#### コスト（asia-northeast1）

**インスタンス料金**
- リージョナル: $0.90/ノード時間
- マルチリージョナル: $3.00/ノード時間

**ストレージ料金**
- $0.30/GB/月

**ネットワーク料金**
- リージョン間: $0.12/GB

---

## DevOps・CI/CD

### Cloud Build

#### 概要
フルマネージドなCI/CDサービス。ソースコードからデプロイまでの自動化パイプラインを構築。

#### 主な機能
- **マルチプラットフォーム**: Docker、buildpacks、カスタムビルダー
- **並列実行**: 複数ステップの同時実行
- **統合**: GitHub、Cloud Source Repositories連携
- **セキュリティ**: バイナリ認証、脆弱性スキャン

#### ビルド構成要素

| 要素 | 説明 | 例 |
|------|------|-----|
| Source | ソースコード | GitHub、Cloud Source Repositories |
| Trigger | 実行トリガー | Push、PR、Webhook |
| Steps | ビルドステップ | Docker build、test、deploy |
| Artifacts | 成果物 | Docker images、JAR files |

#### トリガー種類

| トリガー | 説明 | 用途 |
|----------|------|------|
| Push trigger | コードプッシュ時 | 継続的インテグレーション |
| Pull request | プルリクエスト時 | コードレビュー支援 |
| Tag trigger | タグ作成時 | リリースビルド |
| Manual | 手動実行 | アドホック作業 |
| Scheduled | 定期実行 | 夜間ビルド |

#### ビルド設定例

```yaml
steps:
  # テスト実行
  - name: 'gcr.io/cloud-builders/npm'
    args: ['install']
  - name: 'gcr.io/cloud-builders/npm'
    args: ['test']
  
  # Dockerイメージビルド
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/app:$COMMIT_SHA', '.']
  
  # イメージプッシュ
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/app:$COMMIT_SHA']
  
  # Cloud Runデプロイ
  - name: 'gcr.io/cloud-builders/gcloud'
    args: ['run', 'deploy', 'app', 
           '--image', 'gcr.io/$PROJECT_ID/app:$COMMIT_SHA',
           '--region', 'asia-northeast1']
```

#### 他サービスとの連携
- **Artifact Registry**: イメージとパッケージ保存
- **Cloud Run**: コンテナアプリケーションデプロイ
- **GKE**: Kubernetesクラスターデプロイ
- **Cloud Functions**: サーバーレス関数デプロイ

#### パフォーマンス最適化

| 手法 | 効果 | 実装方法 |
|------|------|----------|
| キャッシュ活用 | ビルド時間短縮 | Docker layer cache |
| 並列実行 | 処理時間短縮 | 複数stepの同時実行 |
| 軽量ベースイメージ | 転送時間短縮 | Alpine、Distroless |
| ワーカープール | 専用リソース | Private pool使用 |

#### コスト

**ビルド時間**
- 最初の120分/日: 無料
- 以降: $0.003/分

**ワーカープール**
- e2-medium: $0.0034/分
- e2-standard-4: $0.0136/分

### Artifact Registry

#### 概要
エンタープライズグレードの成果物管理サービス。コンテナイメージとパッケージの一元管理。

#### 主な機能
- **脆弱性スキャン**: 自動的なセキュリティスキャン
- **IAM統合**: きめ細かいアクセス制御
- **リージョナル複製**: 災害復旧とパフォーマンス向上
- **フォーマット対応**: Docker、Maven、npm、Python等

#### サポート形式

| フォーマット | 用途 | 例 |
|-------------|------|-----|
| Docker | コンテナイメージ | Web app images |
| Maven | Java パッケージ | JAR、WAR files |
| npm | Node.js パッケージ | JavaScript libraries |
| Python | Python パッケージ | pip packages |
| Apt | Debian パッケージ | .deb files |
| Yum | RPM パッケージ | .rpm files |

#### リポジトリタイプ

| タイプ | 説明 | 用途 |
|--------|------|------|
| Standard | 標準リポジトリ | 社内パッケージ |
| Remote | 外部プロキシ | パブリックミラー |
| Virtual | 統合ビュー | 複数リポジトリ統合 |

#### セキュリティ機能

| 機能 | 説明 | 効果 |
|------|------|------|
| 脆弱性スキャン | CVE データベース照合 | セキュリティリスク特定 |
| Binary Authorization | デプロイ時検証 | 承認済みイメージのみ |
| IAM | ロールベースアクセス | 細かい権限制御 |
| 監査ログ | アクセス履歴 | コンプライアンス対応 |

#### 他サービスとの連携
- **Cloud Build**: ビルド成果物の自動保存
- **GKE**: コンテナイメージの取得
- **Cloud Run**: デプロイ用イメージソース
- **Binary Authorization**: セキュリティポリシー適用

#### 管理ベストプラクティス

| 項目 | 推奨事項 | 理由 |
|------|----------|------|
| **タグ戦略** | セマンティックバージョニング | 明確なバージョン管理 |
| **イメージサイズ** | マルチステージビルド | 転送時間・コスト削減 |
| **保持ポリシー** | 古いバージョン自動削除 | ストレージコスト最適化 |
| **リージョン選択** | アプリケーション近接 | ネットワークレイテンシ削減 |

#### コスト

**ストレージ**
- $0.10/GB/月

**ネットワーク**
- 同一リージョン: 無料
- 別リージョン: $0.12/GB
- インターネット: $0.12/GB

**リクエスト**
- Container Registry移行: 無料
- 新規利用: $0.0004/1000リクエスト

---

## コスト最適化

### 環境別推奨構成

#### 開発環境（月額 $100-200）
- GKE: e2-standard-2 × 2ノード（プリエンプティブル）
- Cloud SQL: db-f1-micro
- Cloud Storage: Standard クラス、少量
- Monitoring: 基本アラートのみ

#### ステージング環境（月額 $300-500）
- GKE: e2-standard-2 × 3ノード（通常インスタンス）
- Cloud SQL: db-g1-small (高可用性)
- Cloud Storage: Standard + Nearline
- Monitoring: 包括的監視

#### 本番環境（月額 $1000-3000）
- GKE: e2-standard-4 × 3ノード（リージョナル）
- Cloud SQL: db-n1-standard-2 (高可用性 + レプリカ)
- Cloud Storage: 全クラス + ライフサイクル管理
- Monitoring: フル機能 + 24/7アラート

### コスト監視

#### 予算アラート
```hcl
resource "google_billing_budget" "budget" {
  billing_account = var.billing_account
  display_name    = "${var.environment}-budget"
  
  amount {
    specified_amount {
      currency_code = "USD"
      units         = "500"  # 月額上限
    }
  }
  
  threshold_rules {
    threshold_percent = 0.8  # 80%で警告
  }
}
```

#### コスト分析レポート
- **月次コストレビュー**: 各サービスのコスト推移
- **リソース使用率分析**: 過剰リソースの特定
- **最適化提案**: 自動的なコスト削減提案

---

## 既存リソースのTerraform移行

### 概要

既存のGCPリソースをTerraformで管理するには、`terraform import`コマンドを使用してリソースをTerraform stateに取り込む必要があります。

### 基本的な移行手順

#### 1. 現状調査

```bash
# 既存リソースの確認
gcloud projects list
gcloud compute instances list --project=PROJECT_ID
gcloud sql instances list --project=PROJECT_ID
gcloud container clusters list --project=PROJECT_ID
```

#### 2. Terraformコード作成

既存リソースに合わせてTerraformファイルを作成します。

#### 3. Import実行

```bash
# 例: GCEインスタンスのimport
terraform import google_compute_instance.example projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME

# 例: Cloud SQLインスタンスのimport
terraform import google_sql_database_instance.example PROJECT_ID/INSTANCE_NAME
```

#### 4. 状態確認

```bash
# importが成功したか確認
terraform plan
# 差分がないことを確認（もしくは最小限の差分）
```

### サービス別import例

#### GKE クラスター

```bash
# GKEクラスター
terraform import 'module.gke.google_container_cluster.primary' projects/PROJECT_ID/locations/LOCATION/clusters/CLUSTER_NAME

# ノードプール
terraform import 'module.gke.google_container_node_pool.primary_nodes' projects/PROJECT_ID/locations/LOCATION/clusters/CLUSTER_NAME/nodePools/NODE_POOL_NAME
```

#### Cloud SQL

```bash
# Cloud SQLインスタンス
terraform import 'module.cloud_sql.google_sql_database_instance.instance' PROJECT_ID/INSTANCE_NAME

# データベース
terraform import 'module.cloud_sql.google_sql_database.database["DB_NAME"]' projects/PROJECT_ID/instances/INSTANCE_NAME/databases/DB_NAME

# ユーザー
terraform import 'module.cloud_sql.google_sql_user.users["USER_NAME"]' projects/PROJECT_ID/instances/INSTANCE_NAME/users/USER_NAME
```

#### VPC・ネットワーク

```bash
# VPC
terraform import 'module.vpc.google_compute_network.vpc' projects/PROJECT_ID/global/networks/NETWORK_NAME

# サブネット
terraform import 'module.vpc.google_compute_subnetwork.subnets["SUBNET_KEY"]' projects/PROJECT_ID/regions/REGION/subnetworks/SUBNET_NAME

# ファイアウォールルール
terraform import 'module.vpc.google_compute_firewall.firewall_rules["RULE_KEY"]' projects/PROJECT_ID/global/firewalls/RULE_NAME
```

#### Cloud Storage

```bash
# Cloud Storageバケット
terraform import 'module.storage.google_storage_bucket.buckets["BUCKET_KEY"]' BUCKET_NAME

# バケットIAM
terraform import 'module.storage.google_storage_bucket_iam_binding.bucket_bindings["BINDING_KEY"]' b/BUCKET_NAME
```

#### App Engine

```bash
# App Engineアプリケーション
terraform import 'module.app_engine.google_app_engine_application.app[0]' PROJECT_ID

# App Engineサービス/バージョン
terraform import 'module.app_engine.google_app_engine_standard_app_version.standard_versions["SERVICE_KEY"]' "apps/PROJECT_ID/services/SERVICE_NAME/versions/VERSION_ID"

# ドメインマッピング
terraform import 'module.app_engine.google_app_engine_domain_mapping.domain_mappings["DOMAIN_KEY"]' "apps/PROJECT_ID/domainMappings/DOMAIN_NAME"
```

#### Cloud Run

```bash
# Cloud Runサービス
terraform import 'module.cloud_run.google_cloud_run_service.services["SERVICE_KEY"]' locations/LOCATION/namespaces/PROJECT_ID/services/SERVICE_NAME

# Cloud Run IAM
terraform import 'module.cloud_run.google_cloud_run_service_iam_binding.bindings["BINDING_KEY"]' projects/PROJECT_ID/locations/LOCATION/services/SERVICE_NAME
```

### 大規模移行のベストプラクティス

#### 1. 段階的移行

```bash
# 段階1: VPCとネットワーク
terraform import -target=module.vpc
terraform apply -target=module.vpc

# 段階2: セキュリティ（IAM、Secret Manager）
terraform import -target=module.security
terraform apply -target=module.security

# 段階3: データベース
terraform import -target=module.cloud_sql
terraform apply -target=module.cloud_sql

# 段階4: アプリケーション
terraform import -target=module.gke
terraform apply -target=module.gke
```

#### 2. Import スクリプト例

```bash
#!/bin/bash
# import_existing_resources.sh

PROJECT_ID="your-project-id"
REGION="asia-northeast1"

echo "Importing existing GCP resources..."

# VPC
echo "Importing VPC..."
terraform import 'module.vpc.google_compute_network.vpc' \
  "projects/$PROJECT_ID/global/networks/default"

# Cloud SQL
echo "Importing Cloud SQL instance..."
terraform import 'module.cloud_sql.google_sql_database_instance.instance' \
  "$PROJECT_ID/main-db"

# GKE Cluster
echo "Importing GKE cluster..."
terraform import 'module.gke.google_container_cluster.primary' \
  "projects/$PROJECT_ID/locations/$REGION/clusters/main-cluster"

echo "Import completed. Running terraform plan..."
terraform plan
```

#### 3. 状態確認とバリデーション

```bash
# 1. Import後のplan確認
terraform plan -out=tfplan

# 2. 差分の詳細確認
terraform show tfplan

# 3. Import済みリソースの確認
terraform state list

# 4. 特定リソースの詳細確認
terraform state show 'module.vpc.google_compute_network.vpc'
```

### トラブルシューティング

#### よくある問題と解決法

| 問題 | 原因 | 解決法 |
|------|------|--------|
| Import ID不正 | リソースIDの形式間違い | GCP APIドキュメントで正しい形式確認 |
| 権限エラー | 必要な権限がない | サービスアカウントの権限追加 |
| 設定差分 | Terraformとの設定差異 | 設定値を既存リソースに合わせる |
| 依存関係エラー | 依存リソースが未import | 依存関係順序でimport実行 |

#### Debug方法

```bash
# 詳細ログ出力
export TF_LOG=DEBUG
terraform import ...

# 特定プロバイダーのログ
export TF_LOG_PROVIDER=DEBUG
```

#### Import前の確認事項

1. **バックアップ作成**: 既存リソースの設定をバックアップ
2. **権限確認**: 必要なIAM権限があることを確認
3. **依存関係整理**: リソース間の依存関係を把握
4. **メンテナンス時間**: 本番環境では適切な時間帯に実施

### Import用ツール・スクリプト

#### 1. リソース発見スクリプト

```bash
#!/bin/bash
# discover_resources.sh
PROJECT_ID=$1

echo "=== GCP Resources in $PROJECT_ID ==="

echo "VPC Networks:"
gcloud compute networks list --project=$PROJECT_ID --format="table(name,subnet_mode)"

echo "Subnets:"
gcloud compute networks subnets list --project=$PROJECT_ID --format="table(name,region,range)"

echo "GKE Clusters:"
gcloud container clusters list --project=$PROJECT_ID --format="table(name,location,status)"

echo "Cloud SQL:"
gcloud sql instances list --project=$PROJECT_ID --format="table(name,database_version,region,tier)"

echo "Cloud Storage:"
gsutil ls -p $PROJECT_ID

echo "App Engine Services:"
gcloud app services list --project=$PROJECT_ID 2>/dev/null || echo "No App Engine app"
```

#### 2. 一括Import用Terraformコード生成

```python
# generate_import_commands.py
import subprocess
import json

def get_existing_resources(project_id):
    """既存リソースを取得"""
    resources = {}
    
    # GKE Clusters
    result = subprocess.run([
        'gcloud', 'container', 'clusters', 'list', 
        '--project', project_id, '--format', 'json'
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        clusters = json.loads(result.stdout)
        for cluster in clusters:
            import_cmd = f"""terraform import 'module.gke.google_container_cluster.primary' \\
  projects/{project_id}/locations/{cluster['location']}/clusters/{cluster['name']}"""
            print(import_cmd)

if __name__ == "__main__":
    project_id = input("Enter Project ID: ")
    get_existing_resources(project_id)
```

---

### まとめ

このガイドを参考に、要件に応じた最適なGCPアーキテクチャを構築してください。各サービスの特性を理解し、適切な設定を行うことで、セキュアでコスト効率の良いインフラストラクチャを実現できます。

既存環境からの移行時は、必ず段階的なアプローチを取り、十分なテストとバックアップを行ってから本番適用することを強く推奨します。