.PHONY: help start stop restart logs status shell occ backup health post-install

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

start: ## Start all services
	docker compose up -d

stop: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## Show logs (use make logs service=app to show specific service)
	docker compose logs -f $(service)

status: ## Show service status
	docker compose ps

shell: ## Open shell in Nextcloud container
	docker compose exec -u www-data app bash

occ: ## Run occ command (use: make occ cmd="status")
	docker compose exec -u www-data app php occ $(cmd)

backup: ## Trigger manual backup (requires infrastructure deployment)
	@echo "Backups are managed by the infrastructure deployment."
	@echo "SSH to the server and run: unified-backup.sh"

health: ## Run health check
	./scripts/health-check-api.sh

post-install: ## Run post-installation configuration
	./scripts/post-install.sh

update: ## Update Nextcloud (pull new images and upgrade)
	docker compose pull
	docker compose up -d
	docker compose exec -u www-data app php occ upgrade
	docker compose exec -u www-data app php occ db:add-missing-indices