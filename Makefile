.PHONY: check help

check: ## 校验索引仓（schema / id 唯一 / sha256 / 验签 / 预设引用）
	bash scripts/validate-index.sh

help: ## 列出目标
	@echo "check  校验索引（bash scripts/validate-index.sh）"
	@echo "help   列出目标"
