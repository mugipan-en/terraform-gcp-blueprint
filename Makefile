.PHONY: help init-all plan-dev apply-dev destroy-dev plan-staging apply-staging destroy-staging plan-production apply-production destroy-production fmt lint security validate docs clean test

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# Environment Operations - Development
init-dev: ## Initialize Terraform for development environment
	@echo "🔧 Initializing development environment..."
	cd environments/dev && terraform init

plan-dev: init-dev ## Plan development environment changes
	@echo "📋 Planning development environment..."
	cd environments/dev && terraform plan

apply-dev: ## Apply development environment changes
	@echo "🚀 Applying development environment..."
	cd environments/dev && terraform apply

destroy-dev: ## Destroy development environment
	@echo "💥 Destroying development environment..."
	@read -p "Are you sure you want to destroy DEV environment? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd environments/dev && terraform destroy; \
	else \
		echo "Cancelled."; \
	fi

# Environment Operations - Staging
init-staging: ## Initialize Terraform for staging environment
	@echo "🔧 Initializing staging environment..."
	cd environments/staging && terraform init

plan-staging: init-staging ## Plan staging environment changes
	@echo "📋 Planning staging environment..."
	cd environments/staging && terraform plan

apply-staging: ## Apply staging environment changes
	@echo "🚀 Applying staging environment..."
	cd environments/staging && terraform apply

destroy-staging: ## Destroy staging environment
	@echo "💥 Destroying staging environment..."
	@read -p "Are you sure you want to destroy STAGING environment? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd environments/staging && terraform destroy; \
	else \
		echo "Cancelled."; \
	fi

# Environment Operations - Production
init-production: ## Initialize Terraform for production environment
	@echo "🔧 Initializing production environment..."
	cd environments/production && terraform init

plan-production: init-production ## Plan production environment changes
	@echo "📋 Planning production environment..."
	cd environments/production && terraform plan

apply-production: ## Apply production environment changes (with confirmation)
	@echo "🚀 Applying production environment..."
	@echo "⚠️  WARNING: This will modify PRODUCTION infrastructure!"
	@read -p "Are you sure you want to apply to PRODUCTION? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd environments/production && terraform apply; \
	else \
		echo "Cancelled."; \
	fi

destroy-production: ## Destroy production environment (with double confirmation)
	@echo "💥 Destroying production environment..."
	@echo "⚠️  DANGER: This will destroy ALL PRODUCTION infrastructure!"
	@read -p "Type 'DELETE PRODUCTION' to confirm: " confirm; \
	if [ "$$confirm" = "DELETE PRODUCTION" ]; then \
		cd environments/production && terraform destroy; \
	else \
		echo "Cancelled. You must type exactly 'DELETE PRODUCTION' to confirm."; \
	fi

# Bulk Operations
init-all: ## Initialize all environments
	@echo "🔧 Initializing all environments..."
	cd environments/dev && terraform init
	cd environments/staging && terraform init
	cd environments/production && terraform init

plan-all: ## Plan all environments
	@echo "📋 Planning all environments..."
	@echo "=== Development ==="
	cd environments/dev && terraform plan
	@echo "=== Staging ==="
	cd environments/staging && terraform plan
	@echo "=== Production ==="
	cd environments/production && terraform plan

# Code Quality
fmt: ## Format Terraform code
	@echo "🎨 Formatting Terraform code..."
	terraform fmt -recursive .

lint: ## Run tflint on all configurations
	@echo "🔍 Running tflint..."
	@find . -name "*.tf" -not -path "./.terraform/*" -exec dirname {} \; | sort -u | xargs -I {} sh -c 'echo "Linting {}" && cd "{}" && tflint'

security: ## Run tfsec security scanning
	@echo "🔒 Running security scan..."
	tfsec .

validate: ## Validate Terraform configurations
	@echo "✅ Validating Terraform configurations..."
	@find . -name "*.tf" -not -path "./.terraform/*" -exec dirname {} \; | sort -u | xargs -I {} sh -c 'echo "Validating {}" && cd "{}" && terraform validate'

docs: ## Generate documentation for modules
	@echo "📚 Generating module documentation..."
	@find modules -name "*.tf" -exec dirname {} \; | sort -u | xargs -I {} sh -c 'cd "{}" && terraform-docs markdown table . > README.md'

# Testing
test: ## Run infrastructure tests
	@echo "🧪 Running infrastructure tests..."
	@if [ -d "tests" ]; then \
		cd tests && go test -v .; \
	else \
		echo "No tests directory found. Skipping tests."; \
	fi

test-dev: ## Test development environment connectivity
	@echo "🔍 Testing development environment..."
	@echo "Checking GKE cluster..."
	@if gcloud container clusters get-credentials dev-cluster --region=asia-northeast1 --project=$$(cd environments/dev && terraform output -raw project_id) 2>/dev/null; then \
		kubectl get nodes; \
	else \
		echo "GKE cluster not accessible or not found"; \
	fi

# Utilities
clean: ## Clean up temporary files and caches
	@echo "🧹 Cleaning up..."
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "terraform.tfstate.backup" -delete 2>/dev/null || true
	find . -name "*.tfplan" -delete 2>/dev/null || true

install-tools: ## Install required tools (macOS)
	@echo "📦 Installing required tools..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install tfenv terragrunt tflint tfsec terraform-docs; \
		tfenv install 1.5.7; \
		tfenv use 1.5.7; \
	else \
		echo "Homebrew not found. Please install tools manually:"; \
		echo "- tfenv: https://github.com/tfutils/tfenv"; \
		echo "- Terragrunt: https://terragrunt.gruntwork.io/docs/getting-started/install/"; \
		echo "- tflint: https://github.com/terraform-linters/tflint"; \
		echo "- tfsec: https://github.com/aquasecurity/tfsec"; \
		echo "- terraform-docs: https://terraform-docs.io/"; \
	fi

check-tools: ## Check if required tools are installed
	@echo "🔍 Checking required tools..."
	@command -v terraform >/dev/null 2>&1 || { echo "❌ terraform not found"; exit 1; }
	@command -v terragrunt >/dev/null 2>&1 || { echo "❌ terragrunt not found"; exit 1; }
	@command -v tflint >/dev/null 2>&1 || { echo "❌ tflint not found"; exit 1; }
	@command -v tfsec >/dev/null 2>&1 || { echo "❌ tfsec not found"; exit 1; }
	@echo "✅ All required tools are installed"

# GCP Utilities
gcp-auth: ## Authenticate with GCP
	@echo "🔐 Authenticating with GCP..."
	gcloud auth application-default login

gcp-set-project: ## Set GCP project (interactive)
	@echo "🏗️ Setting GCP project..."
	@read -p "Enter your GCP project ID: " project_id; \
	gcloud config set project "$$project_id"

create-state-bucket: ## Create GCS bucket for Terraform state
	@echo "🪣 Creating state bucket..."
	@read -p "Enter bucket name for Terraform state: " bucket_name; \
	read -p "Enter GCP project ID: " project_id; \
	gsutil mb -p "$$project_id" -c STANDARD -l asia-northeast1 "gs://$$bucket_name"; \
	gsutil versioning set on "gs://$$bucket_name"

# CI/CD Helpers
ci-init: ## Initialize for CI environment
	@echo "🤖 Initializing for CI..."
	terraform --version
	terragrunt --version
	tflint --version
	tfsec --version

ci-validate: ## Run validation in CI
	@echo "🤖 Running CI validation..."
	make fmt
	make validate
	make lint
	make security

# Cost Estimation
cost-estimate: ## Estimate costs for all environments (requires infracost)
	@echo "💰 Estimating infrastructure costs..."
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path=environments/dev --format=table; \
		infracost breakdown --path=environments/staging --format=table; \
		infracost breakdown --path=environments/production --format=table; \
	else \
		echo "infracost not installed. Install from: https://www.infracost.io/docs/"; \
	fi

# Monitoring
show-outputs: ## Show outputs for all environments
	@echo "📊 Showing outputs for all environments..."
	@echo "=== Development ==="
	@cd environments/dev && terraform output 2>/dev/null || echo "No outputs or not initialized"
	@echo "=== Staging ==="
	@cd environments/staging && terraform output 2>/dev/null || echo "No outputs or not initialized"
	@echo "=== Production ==="
	@cd environments/production && terraform output 2>/dev/null || echo "No outputs or not initialized"

graph: ## Generate dependency graph
	@echo "📈 Generating dependency graph..."
	@read -p "Enter environment (dev/staging/production): " env; \
	cd "environments/$$env" && terraform graph | dot -Tpng > "../../$$env-graph.png"; \
	echo "Graph saved as $$env-graph.png"