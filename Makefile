.PHONY: check presets-check help

check: presets-check ## 校验索引仓（索引 schema/验签 + 预设 G-18）
	bash scripts/validate-index.sh

presets-check: ## 校验 8 类预设（id 引用 / 常驻≤3 / RSS 红线 / sha256 / basic 不开箱）
	bash scripts/validate-presets.sh

help: ## 列出目标
	@echo "check          校验索引 + 预设（validate-index.sh + validate-presets.sh）"
	@echo "presets-check  校验 8 类预设（bash scripts/validate-presets.sh）"
	@echo "help           列出目标"
