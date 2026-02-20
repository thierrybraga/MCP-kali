.PHONY: help build up down restart logs shell clean test

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Mostra esta mensagem de ajuda
	@echo "$(BLUE)Kali MCP Pentest Environment - Comandos Disponíveis$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

build: ## Build da imagem Docker
	@echo "$(BLUE)Building Kali MCP Docker image...$(NC)"
	docker-compose build

build-no-cache: ## Build sem cache
	@echo "$(BLUE)Building Kali MCP Docker image (no cache)...$(NC)"
	docker-compose build --no-cache

up: ## Inicia o container
	@echo "$(GREEN)Starting Kali MCP container...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Container started!$(NC)"
	@echo "$(BLUE)MCP Server: http://localhost:3000$(NC)"
	@echo "$(BLUE)Access shell: make shell$(NC)"

down: ## Para o container
	@echo "$(YELLOW)Stopping Kali MCP container...$(NC)"
	docker-compose down

restart: down up ## Reinicia o container

logs: ## Mostra logs do container
	docker-compose logs -f

shell: ## Acessa o shell do container
	@echo "$(GREEN)Accessing Kali MCP shell...$(NC)"
	docker exec -it kali-mcp-pentest /bin/bash

root-shell: ## Acessa shell como root
	@echo "$(GREEN)Accessing Kali MCP shell as root...$(NC)"
	docker exec -it -u root kali-mcp-pentest /bin/bash

ps: ## Mostra processos do container
	docker exec kali-mcp-pentest ps aux

stats: ## Mostra estatísticas de recursos
	docker stats kali-mcp-pentest

clean: ## Remove containers, volumes e imagens
	@echo "$(RED)Cleaning up...$(NC)"
	docker-compose down -v
	docker rmi kali-mcp:latest || true

clean-reports: ## Limpa relatórios antigos
	@echo "$(YELLOW)Cleaning old reports...$(NC)"
	rm -rf reports/* nmap-results/*

test: ## Testa a API do MCP Server
	@echo "$(BLUE)Testing MCP Server...$(NC)"
	@curl -s http://localhost:3000/health | jq . || echo "$(RED)MCP Server not responding$(NC)"

test-nmap: ## Teste rápido do nmap via API
	@echo "$(BLUE)Testing Nmap via MCP API...$(NC)"
	@curl -s -X POST http://localhost:3000/api/scan/nmap \
		-H "Content-Type: application/json" \
		-d '{"target":"scanme.nmap.org","options":"-F"}' | jq .

install-deps: ## Instala dependências adicionais no container
	docker exec kali-mcp-pentest apt-get update
	docker exec kali-mcp-pentest apt-get upgrade -y

backup: ## Backup de reports e configurações
	@echo "$(BLUE)Creating backup...$(NC)"
	@mkdir -p backups
	@tar -czf backups/kali-mcp-backup-$$(date +%Y%m%d_%H%M%S).tar.gz \
		reports/ scripts/ config/ 2>/dev/null || true
	@echo "$(GREEN)Backup created in backups/$(NC)"

update: ## Atualiza a imagem Kali
	@echo "$(BLUE)Updating Kali Linux image...$(NC)"
	docker pull kalilinux/kali-rolling:latest
	$(MAKE) build-no-cache

wordlists: ## Prepara wordlists
	@echo "$(BLUE)Preparing wordlists...$(NC)"
	@mkdir -p wordlists
	docker exec kali-mcp-pentest bash -c "gunzip /root/wordlists/*.gz 2>/dev/null || true"
	@echo "$(GREEN)Wordlists ready$(NC)"

info: ## Mostra informações do ambiente
	@echo "$(BLUE)╔═══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║           Kali MCP Pentest Environment Info               ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Container Status:$(NC)"
	@docker ps -a | grep kali-mcp || echo "  Not running"
	@echo ""
	@echo "$(GREEN)MCP Server:$(NC) http://localhost:3000"
	@echo "$(GREEN)API Docs:$(NC)   http://localhost:3000/"
	@echo ""
	@echo "$(GREEN)Volumes:$(NC)"
	@docker volume ls | grep kali || echo "  No volumes"
	@echo ""

recon: ## Script de reconhecimento completo (usa TARGET=)
	@if [ -z "$(TARGET)" ]; then \
		echo "$(RED)Error: TARGET not specified$(NC)"; \
		echo "Usage: make recon TARGET=192.168.1.0/24"; \
	else \
		echo "$(BLUE)Running full reconnaissance on $(TARGET)...$(NC)"; \
		docker exec kali-mcp-pentest /root/scripts/full_recon.sh $(TARGET); \
	fi

bruteforce: ## Brute force (usa TARGET=, SERVICE=, USER=)
	@if [ -z "$(TARGET)" ] || [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: TARGET and SERVICE required$(NC)"; \
		echo "Usage: make bruteforce TARGET=192.168.1.100 SERVICE=ssh USER=root"; \
	else \
		docker exec kali-mcp-pentest /root/scripts/auto_bruteforce.sh \
			$(TARGET) $(SERVICE) $(if $(USER),-u $(USER),); \
	fi
