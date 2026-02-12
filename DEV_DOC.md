# Developer Documentation

*This document provides technical information for developers working on the Inception project.*

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites and Environment Setup](#prerequisites-and-environment-setup)
- [Configuration Files](#configuration-files)
- [Building the Project](#building-the-project)
- [Docker Compose Management](#docker-compose-management)
- [Container Management](#container-management)
- [Volume Management](#volume-management)
- [Network Configuration](#network-configuration)
- [Service Details](#service-details)
- [Development Workflow](#development-workflow)
- [Debugging](#debugging)
- [Security Considerations](#security-considerations)
- [Performance Optimization](#performance-optimization)
- [Testing](#testing)

---

## Overview

Inception is a multi-container Docker application that demonstrates infrastructure as code principles. The project consists of three services (NGINX, WordPress, MariaDB) orchestrated via Docker Compose, with emphasis on security, modularity, and best practices.

### Technical Stack

- **Containerization:** Docker 20.10+
- **Orchestration:** Docker Compose V2
- **Base Images:** Debian (penultimate stable)
- **Web Server:** NGINX with TLSv1.2/1.3
- **Application:** WordPress + PHP-FPM
- **Database:** MariaDB
- **Automation:** Makefile

### Architecture Principles

1. **Service Isolation:** Each service runs in its own container
2. **No Hacky Patches:** Proper daemon processes, no infinite loops
3. **Custom Images:** All Dockerfiles built from scratch
4. **Named Volumes:** Persistent storage managed by Docker
5. **Bridge Network:** Isolated container communication
6. **Environment Variables:** Configuration via `.env` file
7. **Security First:** No hardcoded credentials, TLS only

---

## Prerequisites and Environment Setup

### System Requirements

**Virtual Machine:**
- Linux distribution (Ubuntu)
- Minimum 2GB RAM
- 10GB free disk space
- Root/sudo access

**Software:**
```bash
# Check Docker version
docker --version  # Should be 20.10+

# Check Docker Compose version
docker-compose --version  # Should be v2.0+

# Check Make
make --version
```

### Initial Setup from Scratch

#### 1. Install Docker (if not installed)

```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker  # Activate the changes
```

#### 2. Clone and Set Up Repository

```bash
# Clone the repository
git clone <repository-url>
cd inception

# Verify structure
ls -la
# Should see: Makefile, srcs/, README.md, etc.
```

#### 3. Set Up Environment Variables

```bash
# Copy example file
touch srcs/.env

# Edit with your values
vim srcs/.env
```

Your `.env` file should contain:
```bash
DOMAIN_NAME=login.42.fr
SQL_DATABASE=example_db
SQL_USER=example_user
SQL_PASSWORD=example_password
SQL_ROOT_PASSWORD=example_root_password
WP_ADMIN_USER=example_admin
WP_ADMIN_PASSWORD=example_admin_password
WP_ADMIN_EMAIL=[admin@example.org](mailto:admin@example.org)
WP_USER=example_username
WP_USER_PASSWORD=example_user_password
WP_USER_EMAIL=[user@example.xyz](mailto:user@example.xyz)
SQL_DATA_PATH=/home/login/data/mysql
WP_DATA_PATH=/home/login/data/wordpress
```

**Important notes:**
- The Makefile will automatically update `/home/*/data/` paths to match your current username
- Never commit this file to Git

#### 4. Start the Infrastructure

```bash
# Single command handles everything
make
```

This will automatically:
1. ✅ Verify and update your `.env` file (`make check-env`)
2. ✅ Add your domain to `/etc/hosts` (`make hosts`)
3. ✅ Create required volume directories (`make init` via `make build`)
4. ✅ Build all Docker images
5. ✅ Start all containers

**You no longer need to manually:**
- Create `/home/user/data/` directories (Makefile does it)
- Add domain to `/etc/hosts` (Makefile does it)
- Update paths in `.env` to match your username (Makefile does it)

The automation makes setup consistent and error-proof across different environments!

---

## Configuration Files



**Important:** Never commit this file to Git!

### Docker Compose Configuration

The `docker-compose.yml` file defines the infrastructure:

```yaml
version: "3"  # 📌 Version of the docker-compose syntax used

services:
  # 🔹 MariaDB service
  mariadb:
    image: mariadb
    build:                      # 🔨 Specifies how to build the image
      context: ./requirements/mariadb  # 📁 Path to the folder containing the Dockerfile
      dockerfile: Dockerfile          # 📄 Dockerfile name
    container_name: mariadb     # 🧱 Custom container name
    env_file: .env              # 📦 Environment variables to load
    volumes:                    # 💾 Persistent volume for MariaDB data
      - mariadb_data:/var/lib/mysql
    networks:                   # 🌐 Docker network (allows services to communicate)
      - inception
    restart: unless-stopped     # 🔁 Restart unless manually stopped

  # 🔹 WordPress service (with PHP-FPM)
  wordpress:
    image: wordpress
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    env_file: .env
    volumes:
      - wordpress_data:/var/www/html  # 📁 Shared folder containing WordPress files
    networks:
      - inception
    depends_on:
      - mariadb               # ⏳ Start WordPress only if MariaDB is ready
    restart: unless-stopped

  # 🔹 NGINX service
  nginx:
    image: nginx
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    env_file: .env
    ports:
      - "443:443"             # 🌍 HTTPS port exposed locally
    volumes:
      - wordpress_data:/var/www/html  # 📁 Share WordPress files with NGINX
    networks:
      - inception
    depends_on:
      - wordpress             # ⏳ NGINX waits until WordPress is ready
    restart: unless-stopped

  # 🔸 Persistent volumes definition
volumes:
  mariadb_data:
    driver: local
  wordpress_data:
    driver: local

# 🔸 Custom network allowing containers to communicate
networks:
  inception:
    driver: bridge            # 🧭 Bridge network: all containers share an isolated network


```

### Makefile Structure and Automation

The project includes an intelligent Makefile that automates setup, configuration, and management.

#### Color Definitions

```makefile
GREEN = \033[0;32m      # Success messages
YELLOW = \033[0;33m     # Information messages
BLUE = \033[0;34m       # [unused]
NC = \033[0m            # Reset color
MAGENTA = \033[0;35m    # [unused]
CYAN = \033[0;36m       # Info messages
GRAY = \033[0;90m       # [unused]
RED = \033[0;31m        # Error messages
```

#### Variables

```makefile
NAME = inception
DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml
ENV_FILE = srcs/.env

# Dynamically read paths from .env file
SQL_DATA_PATH = $(shell grep SQL_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
WP_DATA_PATH = $(shell grep WP_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
DOMAIN_NAME = $(shell grep DOMAIN_NAME $(ENV_FILE) | cut -d '=' -f2)
```

**How it works:** The `$(shell ...)` syntax executes commands at Makefile parse time to extract values from `.env`, making the Makefile dynamic and adaptable to different configurations.

#### Main Commands

**`make all` (default target):**
```makefile
all: check-env hosts logo up
```
Runs a complete setup pipeline:
1. `check-env` - Validates and updates environment
2. `hosts` - Configures domain in /etc/hosts
3. `logo` - Displays ASCII art
4. `up` - Starts the infrastructure (which calls `build`)

**`make check-env`:**
```makefile
check-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)[ERROR] .env file not found. Please create it based on .env.example$(NC)"; \
		exit 1; \
	fi
	@sed -i "s|/home/[^/]\+/data/|/home/$(USER)/data/|g" $(ENV_FILE)
	@echo "$(GREEN)[OK] .env file verified and updated.$(NC)"
```
- Checks if `.env` exists (fails if missing)
- Uses `sed` to replace any `/home/*/data/` path with current `$USER`
- Ensures paths are always correct regardless of who runs it

**`make hosts`:**
```makefile
hosts:
	@if ! grep -q "$(DOMAIN_NAME)" /etc/hosts; then \
		echo "127.0.0.1 $(DOMAIN_NAME)" | sudo tee -a /etc/hosts > /dev/null; \
		echo "$(GREEN)[OK] Domain $(DOMAIN_NAME) added to /etc/hosts.$(NC)"; \
	else \
		echo "$(CYAN)[INFO] Domain $(DOMAIN_NAME) already in /etc/hosts.$(NC)"; \
	fi
```
- Checks if domain already exists in `/etc/hosts`
- Only adds domain if not present (idempotent)
- Requires sudo for write access to `/etc/hosts`

**`make logo`:**
```makefile
logo:
	@echo " _____                     _   _             "
	@echo "|_   _|                   | | (_)            "
	@echo "  | | _ __   ___ ___ _ __ | |_ _  ___  _ __  "
	@echo "  | || '_ \\ / __/ _ \\ '_ \\| __| |/ _ \\| '_ \\ "
	@echo " _| || | | | (_|  __/ |_) | |_| | (_) | | | |"
	@echo " \\___/_| |_|\\___\\___| .__/ \\__|_|\\___/|_| |_|"
	@echo "                    | |                      "
	@echo "                    |_|                      "
```
- Displays ASCII art for visual appeal
- Uses `@` prefix to suppress command echo

**`make init`:**
```makefile
init:
	@echo "$(YELLOW)Creating required host directories...$(NC)"
	mkdir -p $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Directories ready:$(NC) $(SQL_DATA_PATH), $(WP_DATA_PATH)"
```
- Creates volume directories on host if they don't exist
- Uses `-p` flag for safe recursive directory creation
- Paths are read dynamically from `.env`

**`make build`:**
```makefile
build: init
	@echo "$(YELLOW)Building Docker images...$(NC)"
	$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build successful!$(NC)"
```
- Depends on `init` (directories created first)
- Builds all Docker images defined in docker-compose.yml
- Wrapper around `docker compose build`

**`make up`:**
```makefile
up: build
	@echo "$(YELLOW)Starting containers...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Containers are up and running!$(NC)"
```
- Depends on `build` (images built first)
- Starts containers in detached mode (`-d`)
- Automatic startup of entire stack

**`make down`:**
```makefile
down:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Containers stopped.$(NC)"
```
- Stops and removes containers
- Preserves volumes and data
- Safe way to stop infrastructure

**`make clean`:**
```makefile
clean: down
	@echo "$(YELLOW)Removing containers...$(NC)"
	$(DOCKER_COMPOSE) rm -f
	@echo "$(GREEN)Containers removed.$(NC)"
```
- Depends on `down` (containers stopped first)
- Removes stopped containers
- Still preserves volumes

**`make fclean`:**
```makefile
fclean: clean
	@echo "$(YELLOW)Cleaning volumes, networks, and images...$(NC)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans
	sudo rm -rf $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Full clean done.$(NC)"
```
- Complete cleanup command
- Removes: containers, volumes, networks, images
- Deletes data directories on host (requires sudo)
- **Destructive:** All data is permanently lost!

**`make re`:**
```makefile
re: fclean all
```
- Full rebuild: clean everything then rebuild from scratch
- Equivalent to `make fclean && make all`
- **Destructive:** All data is lost

#### .PHONY Declaration

```makefile
.PHONY: all build up down clean fclean re logo init check-env hosts
```
Declares targets as "phony" (not representing actual files), ensuring they always execute even if files with these names exist.

#### Usage Examples

**First time setup:**
```bash
# Single command does everything
make

# Equivalent to:
# make check-env   # Verify .env
# make hosts       # Add domain to /etc/hosts
# make logo        # Display ASCII art
# make build       # Build images (calls init first)
# make up          # Start containers
```

**Daily workflow:**
```bash
# Start work
make

# Stop for the day
make down

# Next day (data preserved)
make
```

**Debugging:**
```bash
# Rebuild specific parts
make check-env     # Only verify environment
make build         # Only rebuild images
make up            # Only start containers

# View logs
docker compose -f srcs/docker-compose.yml logs -f
```

**Clean slate:**
```bash
# Complete reset
make fclean   # Delete everything
make          # Rebuild from scratch
# Or just: make re
```



## Building the Project

### Build Process Overview

The build process:
1. Reads `docker-compose.yml`
2. Builds each Dockerfile in `requirements/`
3. Creates Docker images with appropriate tags
4. Sets up networks and volumes
5. Starts containers in dependency order


### Understanding Dockerfiles

Each service has its own Dockerfile following this pattern:

**Example: NGINX Dockerfile**
```dockerfile
# Use Debian 11 (bullseye) as base image
FROM debian:bullseye

# Update packages, install NGINX and OpenSSL in a single layer and clean apt cache
RUN apt update \
    && apt install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/*

# Remove default NGINX configuration files to avoid conflicts
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

# Create required directories
RUN mkdir -p /var/www/html /etc/nginx/ssl

# Copy custom NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy SSL setup script and make it executable
COPY tools/setup_ssl.sh /setup.sh
RUN chmod +x /setup.sh

# Set permissions on web root directory
RUN chmod -R 755 /var/www/html

# Change ownership to www-data (used by NGINX)
RUN chown -R www-data:www-data /var/www/html

# Generate SSL certificates
RUN /setup.sh

# Expose HTTPS port
EXPOSE 443

# Run NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]

```

**Key Points:**
- Base image: Debian (penultimate stable)
- No `:latest` tag
- Minimal package installation
- Configuration copied at build time
- Scripts for runtime setup
- CMD runs process in foreground (not `tail -f` or infinite loops)

---

## Docker Compose Management

### Core Commands

```bash
# Start services in detached mode
docker-compose -f srcs/docker-compose.yml up -d

# Start with build
docker-compose -f srcs/docker-compose.yml up -d --build

# Stop services (keeps containers)
docker-compose -f srcs/docker-compose.yml stop

# Stop and remove containers
docker-compose -f srcs/docker-compose.yml down

# Stop, remove containers, and volumes
docker-compose -f srcs/docker-compose.yml down -v

# View running services
docker-compose -f srcs/docker-compose.yml ps

# View logs
docker-compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f

# Logs for specific service
docker-compose -f srcs/docker-compose.yml logs -f wordpress

# Restart specific service
docker-compose -f srcs/docker-compose.yml restart nginx

# Execute command in service
docker-compose -f srcs/docker-compose.yml exec wordpress sh


```

### Service Dependencies

Services start in this order due to `depends_on`:
1. **MariaDB** (no dependencies)
2. **WordPress** (depends on MariaDB)
3. **NGINX** (depends on WordPress)

**Note:** `depends_on` only waits for containers to start, not for services to be fully ready. Implement health checks or wait scripts for production.=

---

## Container Management

### Inspecting Containers

```bash
# List all containers
docker ps -a

# Inspect container configuration
docker inspect nginx

# View container resource usage
docker stats
```

### Resource Management

```bash
# View Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune
```

---

## Volume Management

### Volume Commands

```bash
# List all volumes
docker volume ls

# Inspect volume configuration
docker volume inspect inception_wordpress_data
docker volume inspect inception_mariadb_data

# Check volume contents
ls -la /home/$(whoami)/data/wordpress/
ls -la /home/$(whoami)/data/mariadb/

# Check volume size
du -sh /home/$(whoami)/data/*

# Check table database
docker exec -it mariadb mysql -u dbajeux -pimagine -e "USE wordpress; SHOW TABLES;"

# Check content of one table database
export $(grep -v '^#' .env | xargs) && docker exec -it mariadb mysql -u $SQL_USER -p$SQL_PASSWORD -e "SELECT * FROM <name_of_tabe>;" $SQL_DATABASE

# Remove all volumes (WARNING: deletes data!)
docker-compose -f srcs/docker-compose.yml down -v
```

### Port Mapping

Only NGINX exposes ports to the host:

```yaml
ports:
  - "443:443"  # Host port 443 → Container port 443
```

Other services do NOT expose ports:
- WordPress: Accessible only within Docker network
- MariaDB: Accessible only within Docker network

---

## Service Details

### NGINX Service

**Purpose:** HTTPS web server and reverse proxy

**Key Files:**
- `requirements/nginx/Dockerfile`
- `requirements/nginx/conf/nginx.conf`
- `requirements/nginx/tools/setup.sh`

**Configuration highlights:**
```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    
    server_name login.42.fr;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    root /var/www/html;
    index index.php;
    
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Commands:**
```bash
# Test NGINX configuration
docker exec nginx nginx -t

# Reload NGINX
docker exec nginx nginx -s reload

# View access logs
docker exec nginx tail -f /var/log/nginx/access.log

# View error logs
docker exec nginx tail -f /var/log/nginx/error.log
```

### WordPress Service

**Purpose:** PHP-FPM application server running WordPress

**Key Files:**
- `requirements/wordpress/Dockerfile`
- `requirements/wordpress/conf/www.conf`
- `requirements/wordpress/tools/setup.sh`

**Initialization tasks:**
1. Download WordPress core files
2. Configure `wp-config.php` with database credentials
3. Install WordPress (wp-cli)
4. Create admin user
5. Set up permalinks

**Commands:**
```bash
# Check WordPress version
docker exec wordpress wp --info --allow-root

# List installed plugins
docker exec wordpress wp plugin list --allow-root

# Check database connection
docker exec wordpress wp db check --allow-root

# Update WordPress
docker exec wordpress wp core update --allow-root

# Create new post
docker exec wordpress wp post create --post_title="Hello" --post_content="World" --post_status=publish --allow-root
```

### MariaDB Service

**Purpose:** MySQL-compatible database server

**Key Files:**
- `requirements/mariadb/Dockerfile`
- `requirements/mariadb/conf/my.cnf`
- `requirements/mariadb/tools/setup.sh`

**Initialization tasks:**
1. Initialize MySQL data directory
2. Create root password
3. Create WordPress database
4. Create WordPress user with privileges

**Commands:**
```bash
# Connect to MySQL CLI
docker exec -it mariadb mysql -u root -p

# Show databases
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Show WordPress tables
docker exec mariadb mysql -u root -p wordpress -e "SHOW TABLES;"
```

---


## Debugging

#### SSL/TLS Issues

```bash
# Test certificate
openssl s_client -connect login.42.fr:443 -tls1_2
openssl s_client -connect login.42.fr:443 -tls1_3

# Check certificate details
docker exec nginx openssl x509 -in /etc/nginx/ssl/nginx.crt -text -noout

# Verify NGINX config
docker exec nginx nginx -t
```


### SSL/TLS Configuration

**Generate self-signed certificate:**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx.key -out nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=login.42.fr"
```

**Enforce TLS 1.2/1.3:**
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
```



### Network Security

```yaml
# Internal network only
networks:
  inception:
    driver: bridge

# Only expose necessary ports
ports:
  - "443:443"  # Only HTTPS
```

---


## Data Storage and Persistence

### Where Data is Stored

**On Host Machine:**
```
/home/login/data/
├── wordpress/          # WordPress installation files
│   ├── wp-content/
│   ├── wp-config.php
│   └── ...
└── mariadb/            # MariaDB database files
    ├── mysql/
    ├── wordpress/      # WordPress database
    └── ...
```

**Inside Containers:**
- WordPress: `/var/www/html/` (mounted to host)
- MariaDB: `/var/lib/mysql/` (mounted to host)
- NGINX: No persistent data (config in image)

## Useful Commands Reference

### Quick Command Reference

```bash
# Project Management
make                    # Build and start
make down               # Stop services
make logs               # View logs
make fclean             # Clean everything
make re                 # Rebuild from scratch

# Docker Compose
docker-compose -f srcs/docker-compose.yml ps              # List services
docker-compose -f srcs/docker-compose.yml logs -f         # Follow logs
docker-compose -f srcs/docker-compose.yml restart nginx   # Restart service
docker-compose -f srcs/docker-compose.yml exec wordpress sh  # Enter container

# Container Management
docker ps               # List running containers
docker ps -a            # List all containers
docker logs <name>      # View logs
docker exec -it <name> sh  # Enter container
docker inspect <name>   # Detailed info

# Volume Management
docker volume ls        # List volumes
docker volume inspect <name>  # Volume details
du -sh /home/$(whoami)/data/*  # Check size

# Network Management
docker network ls       # List networks
docker network inspect inception_inception  # Network details

# System Cleanup
docker system df        # Disk usage
docker system prune -a  # Clean all unused resources
```

---

**Document Version:** 1.0  
**Last Updated:** February 2026  
**For:** 42 Inception Project - Developer Reference