# Include modular makefiles
include makefiles/git.mk
include makefiles/docker.mk

# Default target
.DEFAULT_GOAL := help

# Main project targets
.PHONY: setup install build clean help



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




