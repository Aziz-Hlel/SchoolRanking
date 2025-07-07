# makefiles/git.mk - Git operations module
# Professional git workflow automation

# Git configuration
DEFAULT_BRANCH := main
# Service directories
FRONTEND_DIR := ./Frontend
BACKEND_DIR := ./Backend

# Set COMMIT_MSG to the value of m
COMMIT_MSG := $(m)




# Git push operations
.PHONY:  git-push-backend git-push-frontend git-push-submodules git-push-main

define require_msg_check # Runtime check function for commit message
	@if [ -z "$(m)" ]; then \
		echo "❌ Commit message (m) is required. Usage: make <target> m=\"Your commit message\""; \
		exit 1; \
	fi
endef

git-push-backend:  ## Push backend repository
	$(require_msg_check)
	@echo "⚙️  Pushing backend..."
	@cd $(BACKEND_DIR) && \
	git add . && \
	git commit -m "$(COMMIT_MSG)" || true && \
	git push origin $(DEFAULT_BRANCH) || { echo "❌ Backend push failed"; exit 1; }
	@echo "✅ Backend pushed successfully"

git-push-frontend:  ## Push frontend repository
	$(require_msg_check)
	@echo "📱 Pushing frontend..."
	@cd $(FRONTEND_DIR) && \
	git add . && \
	git commit -m "$(COMMIT_MSG)" || true && \
	git push origin $(DEFAULT_BRANCH) || { echo "❌ Frontend push failed"; exit 1; }
	@echo "✅ Frontend pushed successfully"



git-push-submodules: ## Push submodule pointer updates in main repo to keep submodules in sync
	$(require_msg_check)
	@echo "📱 Pushing main repository ..."
	git add Backend && \
	git add Frontend && \
	git commit -m "submodule pointers" && \
	git push origin $(DEFAULT_BRANCH) || { echo "❌ Submodule pointer push failed"; exit 1; }
	


git-push-main:  ## Push all repositories
	$(require_msg_check)
	@echo "🚀 Pushing main repository..."
	git add .
	git reset Backend
	git reset Frontend
	git commit -m "$(COMMIT_MSG)" || true
	git push origin $(DEFAULT_BRANCH)
	@echo "✅ Main repository pushed successfully"

#
#
# Git pull operations
.PHONY: git-pull-all git-pull-frontend git-pull-backend 

git-pull-all: ## Pull all repositories
	@echo "⬇️  Pulling all repositories..."

	@echo "🗂️  Pulling root repository..."
	@git checkout $(DEFAULT_BRANCH)
	@git pull origin $(DEFAULT_BRANCH)

	@$(MAKE) git-pull-frontend
	@$(MAKE) git-pull-backend

	@echo "✅ All repositories pulled successfully"


git-pull-frontend: ## Pull frontend repository
	@echo "📱 Pulling frontend..."
	@cd $(FRONTEND_DIR) && git checkout $(DEFAULT_BRANCH) && git pull origin $(DEFAULT_BRANCH)

git-pull-backend: ## Pull backend repository
	@echo "⚙️  Pulling backend..."
	@cd $(BACKEND_DIR) && git checkout $(DEFAULT_BRANCH) && git pull origin $(DEFAULT_BRANCH)




