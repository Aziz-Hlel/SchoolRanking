# Include modular makefiles
include makefiles/git.mk
include makefiles/docker.mk
include makefiles/db.mk

# Default target
.DEFAULT_GOAL := help

# Main project targets
.PHONY: setup help


# Colors for output
GREEN := \033[0;32m]
YELLOW := \033[1;33m]
RED := \033[0;31m]
NC := \033[0m] # No Color

# Help target
help: ## Show this help message
	@echo "$(PROJECT_NAME) - Available Commands:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "📁 Modular Commands:"
	@echo "  Git:        make git-help"
	@echo "  Docker:     make docker-help"
	@echo "  db:		 make db-help"





setup: ## Initial setup for new developers
	@echo "$(GREEN)🚀 Setting up development environment...$(NC)"
	@git submodule update --init --recursive
	@$(MAKE) git-pull-all
	@echo "$(GREEN)✅ Setup complete! Edit .env file and run 'make dev'$(NC)"