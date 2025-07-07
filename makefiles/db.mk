
# Main project targets
.PHONY: help


# Colors for output
GREEN := \033[0;32m]
YELLOW := \033[1;33m]
RED := \033[0;31m]
NC := \033[0m] # No Color

# Help target
help: ## Show this help message
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "📁 Modular Commands:"
	@echo "  Git:        make git-help"
	@echo "  Docker:     make docker-help"  
#
#
db-backup: ## Backup database
	@echo "$(GREEN)💾 Creating database backup...$(NC)"
	bash ./scripts/backup.sh
#
#
db-restore: ## Restore database
	@echo "$(GREEN)💾 Restoring database...$(NC)"
	bash ./scripts/restore.sh