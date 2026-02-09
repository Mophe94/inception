#############################################
# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m
MAGENTA = \033[0;35m
CYAN = \033[0;36m
GRAY = \033[0;90m
RED = \033[0;31m
#############################################

NAME = inception
DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml
ENV_FILE = srcs/.env

# Récupère les chemins définis dans le .env
SQL_DATA_PATH = $(shell grep SQL_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
WP_DATA_PATH = $(shell grep WP_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
DOMAIN_NAME = $(shell grep DOMAIN_NAME $(ENV_FILE) | cut -d '=' -f2)

#############################################

all: check-env hosts logo up

logo:
	@echo " _____                     _   _             "
	@echo "|_   _|                   | | (_)            "
	@echo "  | | _ __   ___ ___ _ __ | |_ _  ___  _ __  "
	@echo "  | || '_ \\ / __/ _ \\ '_ \\| __| |/ _ \\| '_ \\ "
	@echo " _| || | | | (_|  __/ |_) | |_| | (_) | | | |"
	@echo " \\___/_| |_|\\___\\___| .__/ \\__|_|\\___/|_| |_|"
	@echo "                    | |                      "
	@echo "                    |_|                      "

check-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)[ERROR] .env file not found. Please create it based on .env.example$(NC)"; \
		exit 1; \
	fi
	@sed -i "s|/home/[^/]\+/data/|/home/$(USER)/data/|g" $(ENV_FILE)
	@echo "$(GREEN)[OK] .env file verified and updated.$(NC)"

hosts:
	@if ! grep -q "$(DOMAIN_NAME)" /etc/hosts; then \
		echo "127.0.0.1 $(DOMAIN_NAME)" | sudo tee -a /etc/hosts > /dev/null; \
		echo "$(GREEN)[OK] Domain $(DOMAIN_NAME) added to /etc/hosts.$(NC)"; \
	else \
		echo "$(CYAN)[INFO] Domain $(DOMAIN_NAME) already in /etc/hosts.$(NC)"; \
	fi

init:
	@echo "$(YELLOW)Creating required host directories...$(NC)"
	mkdir -p $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Directories ready:$(NC) $(SQL_DATA_PATH), $(WP_DATA_PATH)"

build: init
	@echo "$(YELLOW)Building Docker images...$(NC)"
	$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build successful!$(NC)"

up: build
	@echo "$(YELLOW)Starting containers...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Containers are up and running!$(NC)"

down:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Containers stopped.$(NC)"

clean: down
	@echo "$(YELLOW)Removing containers...$(NC)"
	$(DOCKER_COMPOSE) rm -f
	@echo "$(GREEN)Containers removed.$(NC)"

fclean: clean
	@echo "$(YELLOW)Cleaning volumes, networks, and images...$(NC)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans
	sudo rm -rf $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Full clean done.$(NC)"

# re supprime tout et relance tout, incluant les checks
re: fclean all

.PHONY: all build up down clean fclean re logo init check-env hosts

