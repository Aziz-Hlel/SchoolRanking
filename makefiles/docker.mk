# makefiles/docker.mk - Docker operations module
# Professional Docker workflow automation





docker-dev-up: ## Start development environment
	@echo "🚀 Starting development environment..."
	@docker compose -f compose.dev.yml up --build
	@echo "✅ Development environment started"


docker-stage-up : ## Start staging environment
	@echo "🚀 Starting staging environment..."
	@docker compose -f compose.stage.yml up --build
	@echo "✅ Staging environment started"

docker-up : ## Start production environment
	@echo "🚀 Starting production environment..."
	@docker compose up --build
	@echo "✅ Production environment started"




# Maintenance operations
.PHONY: docker-clean docker-prune docker-system-prune

# docker-clean: ## Clean Docker images and containers
# 	@echo "🧹 Cleaning Docker resources..."
# 	@docker-compose -f $(DOCKER_COMPOSE_FILE) down --volumes --remove-orphans
# 	@docker system prune -f
# 	@echo "✅ Docker cleanup completed"

docker-prune: ## Remove unused Docker resources
	@echo "🧹 Pruning unused Docker resources..."
	@docker system prune -a -f --volumes
	@echo "✅ Docker pruning completed"

docker-system-prune: ## Deep clean Docker system
	@echo "🧹 Deep cleaning Docker system..."
	@docker system prune -a -f --volumes
	@docker network prune -f
	@docker volume prune -f
	@echo "✅ Docker system deep cleaned"