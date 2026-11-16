# Developer Documentation

> Technical reference for developers working on the **Inception** project.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites and Environment Setup](#prerequisites-and-environment-setup)
  - [System Requirements](#system-requirements)
  - [Create the Virtual Machine](#0-create-the-virtual-machine)
  - [Install Docker](#1-install-docker)
  - [Add Docker's GPG Key](#2-add-dockers-official-gpg-key)
  - [Add Docker's Repository](#3-add-dockers-official-repository)
  - [Install Docker Engine](#4-install-docker-engine--all-plugins)
  - [Verify the Installation](#5-verify-the-installation)
  - [Add User to Docker Group](#6-add-your-user-to-the-docker-group)
  - [Clone and Set Up Repository](#7-clone-and-set-up-repository)
  - [Set Up Environment Variables](#8-set-up-environment-variables)
  - [Start the Infrastructure](#9-start-the-infrastructure)
- [Configuration Files](#configuration-files)
  - [Docker Compose Configuration](#docker-compose-configuration)
  - [Makefile Structure and Automation](#makefile-structure-and-automation)
- [Building the Project](#building-the-project)
- [Docker Compose Management](#docker-compose-management)
- [Container Management](#container-management)
- [Volume Management](#volume-management)
- [Network Configuration](#network-configuration)
- [Service Details](#service-details)
  - [NGINX](#nginx-service)
  - [WordPress](#wordpress-service)
  - [MariaDB](#mariadb-service)
- [Debugging](#debugging)
- [Security Considerations](#security-considerations)
- [Data Storage and Persistence](#data-storage-and-persistence)
- [Useful Commands Reference](#useful-commands-reference)
- [Known Limitations and Possible Improvements](#known-limitations-and-possible-improvements)

---

## Overview

Inception is a multi-container Docker application that demonstrates infrastructure as code principles. The project consists of three services - **NGINX**, **WordPress**, and **MariaDB** - orchestrated via Docker Compose, with emphasis on security, modularity, and best practices.

### Technical Stack

| Component | Technology |
|---|---|
| Containerization | Docker |
| Orchestration | Docker Compose |
| Base Images | Debian 12 (bookworm), the penultimate stable release |
| Web Server | NGINX with TLSv1.2/1.3 |
| Application | WordPress + PHP-FPM 8.2 (installed with WP-CLI) |
| Database | MariaDB |
| Automation | Makefile |

### Architecture Principles

1. **Service Isolation** - Each service runs in its own container
2. **No Hacky Patches** - Proper daemon processes, no infinite loops
3. **Custom Images** - All Dockerfiles built from scratch
4. **Named Volumes** - Persistent storage managed by Docker
5. **Bridge Network** - Isolated container communication
6. **Environment Variables** - Configuration via `.env` file
7. **Security First** - No hardcoded credentials, TLS only

---

## Prerequisites and Environment Setup

### System Requirements

**Virtual Machine (or WSL2 on Windows):**
- Linux distribution (Debian 12 recommended - any recent Debian/Ubuntu works)
- Minimum 2 GB RAM
- 10 GB free disk space
- Root / sudo access

**Verify installed tools:**

```bash
# Check Docker version
docker --version
# Check Docker Compose version
docker compose version
# Check Make
make --version
```

---

### 0. Create the Virtual Machine

1. Download a Debian ISO (e.g. Debian 12 netinst) and create a new VM (VirtualBox, UTM…): 2 CPUs, 2 GB RAM, 20 GB disk is comfortable.
2. Run the installer without the guided setup:
   - **Hostname:** a clear name, e.g. `inception-vm` - domain can stay empty
   - **Users:** set a root password (or leave it empty to use `sudo`) and create your main user
   - **Partitioning:** guided, entire disk (LVM is not required)
   - **Software selection:** uncheck everything except **SSH server** and **standard system utilities**
3. After the first boot, install the base tools:

```bash
su -
apt-get update && apt-get install -y sudo git vim make build-essential
usermod -aG sudo <your_user>   # then log out and back in
```

| Package | Why |
|---|---|
| `sudo` | Run admin commands as your user (needed by `make hosts` and `make fclean`) |
| `openssh-server` | Work on the VM remotely (installed by the "SSH server" option) |
| `git` | Clone the repository |
| `vim` / `nano` | Edit configuration files |
| `make`, `build-essential` | Run the Makefile |

---

### 1. Install Docker

#### Required Dependencies

| Package | Role |
|---|---|
| `ca-certificates` | Verifies SSL certificates and secures HTTPS connections |
| `curl` | Fetches files and communicates with APIs over HTTP/HTTPS |
| `gnupg` | Verifies that downloaded packages genuinely come from Docker |
| `lsb-release` | Provides distribution info to configure the correct repository |

```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install -y ca-certificates curl gnupg lsb-release
```

---

### 2. Add Docker's Official GPG Key

Every Docker package is signed with a private key. Your system needs the corresponding public key to verify this signature. We download it and install it into `/etc/apt/keyrings/`.

> **Result:** When you run `apt install docker-ce`, Debian will verify the package is genuine and untampered.

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

**Command breakdown:**

| Part | Role |
|---|---|
| `mkdir -p /etc/apt/keyrings` | Creates the GPG key storage folder if needed |
| `curl -fsSL ...` | Downloads Docker's official GPG key |
| `gpg --dearmor` | Converts the key into a format readable by apt |
| `-o /etc/apt/keyrings/docker.gpg` | Saves the converted key |

---

### 3. Add Docker's Official Repository

By default, Debian does not include the most recent Docker packages. Adding Docker's official repository tells `apt` where to look for `docker-ce`.

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**Command breakdown:**

| Part | Role |
|---|---|
| `echo "deb ... stable"` | Creates the repository entry line |
| `arch=$(dpkg --print-architecture)` | Auto-detects your machine's architecture (amd64, arm64, etc.) |
| `signed-by=/etc/apt/keyrings/docker.gpg` | Tells apt to use the GPG key from step 2 |
| `$(lsb_release -cs)` | Retrieves your Debian codename (e.g. `bookworm`) |
| `sudo tee /etc/apt/sources.list.d/docker.list` | Writes the entry into a dedicated Docker repo file |
| `> /dev/null` | Suppresses output to keep the terminal clean |

> **Result:** Your Debian system now knows about the official Docker repository.

---

### 4. Install Docker Engine + All Plugins

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**Package breakdown:**

| Package | Role |
|---|---|
| `docker-ce` | Main Docker engine - manages containers |
| `docker-ce-cli` | Command-line interface (`docker run`, `docker ps`, …) |
| `containerd.io` | Container runtime - executes containers |
| `docker-buildx-plugin` | Extension for building advanced Docker images |
| `docker-compose-plugin` | Native Docker Compose v2 support (`docker compose`) |

---

### 5. Verify the Installation

```bash
docker --version
docker compose version
```

> **Result:** Displays the version of each tool.

```bash
docker run hello-world
```

> **Result:** Launches an ephemeral container, prints a confirmation message, then shuts down.

---

### 6. Add Your User to the Docker Group

```bash
sudo usermod -aG docker $USER
```

> Log out and back in for this change to take effect.

---

### 7. Clone and Set Up Repository

```bash
# Clone the repository
git clone git@github.com:Mophe94/inception.git
cd inception

# Verify structure
ls -la
# Expected: Makefile, srcs/, README.md, etc.
```

---

### 8. Set Up Environment Variables

```bash
# Create your .env from the template
cp srcs/.env.example srcs/.env

# Edit with your values
vim srcs/.env
```

The template contains every expected variable (example values):

```bash
DOMAIN_NAME=login.42.fr
SQL_DATABASE=example_db
SQL_USER=example_user
SQL_PASSWORD=example_password
SQL_ROOT_PASSWORD=example_root_password
WP_ADMIN_USER=example_superuser
WP_ADMIN_PASSWORD=example_superuser_password
WP_ADMIN_EMAIL=superuser@example.org
WP_USER=example_username
WP_USER_PASSWORD=example_user_password
WP_USER_EMAIL=user@example.xyz
WP_VERSION=6.4
SQL_DATA_PATH=/home/login/data/mariadb
WP_DATA_PATH=/home/login/data/wordpress
```

> **Important:** `srcs/.env` is git-ignored - never commit it.  
> The Makefile will automatically update `/home/*/data/` paths to match your current username.

---

### 9. Start the Infrastructure

```bash
# Single command handles everything
make
```

This single command handles the entire setup automatically:

1. ✅ Verifies and updates your `.env` file (`make check-env`)
2. ✅ Adds your domain to `/etc/hosts` (`make hosts`)
3. ✅ Creates required volume directories (`make init`)
4. ✅ Builds all Docker images
5. ✅ Starts all containers

> You no longer need to manually create data directories, add the domain to `/etc/hosts`, or update paths in `.env`.

---

## Configuration Files

> **Important:** Never commit `.env` to Git.

### Docker Compose Configuration

The `srcs/docker-compose.yml` file defines the full infrastructure:

```yaml
services:
  # 🔹 MariaDB Service
  mariadb:
    image: mariadb
    build:                      # 🔨 Indicates how to build the image
      context: ./requirements/mariadb  # 📁 Path to the folder containing the Dockerfile
      dockerfile: Dockerfile          # 📄 Dockerfile name
    container_name: mariadb     # 🧱 Custom container name
    env_file: .env              # 📦 Environment variables to load
    volumes:                    # 💾 Persistent volume for MariaDB data
      - mariadb_data:/var/lib/mysql
    networks:                   # 🌐 Docker network (so services can see each other)
      - inception
    restart: unless-stopped     # 🔁 Restarts unless manually stopped

  # 🔹 WordPress Service (with PHP-FPM)
  wordpress:
    image: wordpress
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    env_file: .env
    volumes:
      - wordpress_data:/var/www/html  # 📁 Shared folder containing WP files
    networks:
      - inception
    depends_on:
      - mariadb               # ⏳ Starts WordPress only if MariaDB is ready
    restart: unless-stopped

  # 🔹 NGINX Service
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
      - wordpress_data:/var/www/html  # 📁 Shares WordPress files with NGINX
    networks:
      - inception
    depends_on:
      - wordpress             # ⏳ NGINX waits for WordPress to be ready
    restart: unless-stopped

  # 🔸 Persistent volumes definition
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${SQL_DATA_PATH}   # ← path on your host

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${WP_DATA_PATH}

# 🔸 Custom network so containers can communicate
networks:
  inception:
    driver: bridge            # 🧭 Bridge network: all containers share an isolated network
```

---

### Makefile Structure and Automation

The project includes an intelligent Makefile that automates setup, configuration, and management.

#### Color Definitions

```makefile
GREEN   = \033[0;32m    # Success messages
YELLOW  = \033[0;33m    # Information messages
CYAN    = \033[0;36m    # Info messages
RED     = \033[0;31m    # Error messages
NC      = \033[0m       # Reset color
```

#### Variables

```makefile
NAME          = inception
DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml
ENV_FILE      = srcs/.env

# Dynamically read paths from .env file
SQL_DATA_PATH = $(shell grep SQL_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
WP_DATA_PATH  = $(shell grep WP_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
DOMAIN_NAME   = $(shell grep DOMAIN_NAME $(ENV_FILE) | cut -d '=' -f2)
```

> `$(shell ...)` executes at Makefile parse time, making it dynamic and adaptable across environments.

---

#### Main Commands

**`make` / `make all` (default target):**

```makefile
all: check-env hosts logo up
```

Runs the full setup pipeline: environment check → host config → build → start.

---

**`make check-env`:**

```makefile
check-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)[ERROR] .env file not found. Run: cp srcs/.env.example srcs/.env$(NC)"; \
		exit 1; \
	fi
	@sed -i "s|/home/[^/]\+/data/|/home/$(USER)/data/|g" $(ENV_FILE)
	@echo "$(GREEN)[OK] .env file verified and updated.$(NC)"
```

Checks if `.env` exists and updates the `/home/*/data/` path to match the current `$USER`.

---

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

Idempotent: only adds the domain if it is not already present.

---

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

---

**`make init`:**

```makefile
init:
	@echo "$(YELLOW)Creating required host directories...$(NC)"
	mkdir -p $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Directories ready:$(NC) $(SQL_DATA_PATH), $(WP_DATA_PATH)"
```

Creates volume directories on the host if they don't exist. Paths are read dynamically from `.env`.

---

**`make build`:**

```makefile
build: init
	@echo "$(YELLOW)Building Docker images...$(NC)"
	$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build successful!$(NC)"
```

Depends on `init`. Builds all Docker images defined in `docker-compose.yml`.

---

**`make up`:**

```makefile
up: build
	@echo "$(YELLOW)Starting containers...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Containers are up and running!$(NC)"
```

Depends on `build`. Starts all containers in detached mode.

---

**`make down`:**

```makefile
down:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Containers stopped.$(NC)"
```

Stops and removes containers. Preserves volumes and data.

---

**`make clean`:**

```makefile
clean: down
	@echo "$(YELLOW)Removing containers...$(NC)"
	$(DOCKER_COMPOSE) rm -f
	@echo "$(GREEN)Containers removed.$(NC)"
```

Removes stopped containers. Still preserves volumes.

---

**`make fclean`:**

```makefile
fclean: clean
	@echo "$(YELLOW)Cleaning volumes, networks, and images...$(NC)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans
	sudo rm -rf $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Full clean done.$(NC)"
```

> ⚠️ **Destructive.** Removes containers, volumes, networks, images, and all host data directories. All data is permanently lost.

---

**`make re`:**

```makefile
re: fclean all
```

Full rebuild: wipes everything then rebuilds from scratch.

> ⚠️ **Destructive.** All data is lost.

---

**`.PHONY` Declaration:**

```makefile
.PHONY: all build up down clean fclean re logo init check-env hosts
```

Declares all targets as phony so they always execute, even if files with those names exist.

---

#### Usage Examples

**First-time setup:**

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

---

## Building the Project

### Build Process Overview

1. Reads `docker-compose.yml`
2. Builds each Dockerfile in `requirements/`
3. Creates Docker images with appropriate tags
4. Sets up networks and volumes
5. Starts containers in dependency order

### Understanding Dockerfiles

Each service has its own Dockerfile following this pattern:

**Example - NGINX Dockerfile:**

```dockerfile
# Base image: Debian 12 (bookworm), the penultimate stable release
FROM debian:bookworm

# Updates packages, installs NGINX and OpenSSL in a single layer and cleans the apt cache
RUN apt-get update \
    && apt-get install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/*

# Removes default NGINX configuration files to avoid conflicts
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

# Copies the custom NGINX configuration file into the container
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copies the SSL configuration script and makes it executable
COPY tools/setup_ssl.sh /setup.sh
RUN chmod +x /setup.sh

# Grants read/write/execute permissions to the owner and read/execute to others
RUN chmod -R 755 /var/www/html

# Changes the file owner to 'www-data' (used by NGINX)
RUN chown -R www-data:www-data /var/www/html

# Declares the HTTPS port as exposed
EXPOSE 443

# Uses the SSL configuration script as the entrypoint
ENTRYPOINT ["bash", "/setup.sh"]
```

**Key principles:**
- Base image: Debian 12 (bookworm), pinned by tag - never `:latest`
- Minimal package installation
- Configuration copied at build time
- The TLS certificate is generated at container start by `setup_ssl.sh`, which then `exec`s NGINX in the foreground
- The `ENTRYPOINT` script ends with `exec`, so the service runs in the foreground as PID 1 - no `tail -f` or infinite loops

---

## Docker Compose Management

### Core Commands

```bash
# Start services in detached mode
docker compose -f srcs/docker-compose.yml up -d

# Start with forced rebuild
docker compose -f srcs/docker-compose.yml up -d --build

# Stop services (keeps containers)
docker compose -f srcs/docker-compose.yml stop

# Stop and remove containers
docker compose -f srcs/docker-compose.yml down

# Stop, remove containers and volumes
docker compose -f srcs/docker-compose.yml down -v

# View running services
docker compose -f srcs/docker-compose.yml ps

# View all logs
docker compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# Logs for a specific service
docker compose -f srcs/docker-compose.yml logs -f wordpress

# Restart a specific service
docker compose -f srcs/docker-compose.yml restart nginx

# Execute a command in a container
docker compose -f srcs/docker-compose.yml exec wordpress sh
```

### Service Start Order

Services start in this order due to `depends_on`:

1. **MariaDB** - no dependencies
2. **WordPress** - depends on MariaDB
3. **NGINX** - depends on WordPress

> **Note:** `depends_on` only waits for containers to *start*, not for services to be ready. That is why `setup_wordpress.sh` waits for MariaDB with `mysqladmin ping` (up to 30 attempts) before running WP-CLI.

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
# Clean up all unused resources
docker system prune -a
# Remove stopped containers only
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

# Check volume contents on host
ls -la /home/$(whoami)/data/wordpress/
ls -la /home/$(whoami)/data/mariadb/

# Check volume sizes
du -sh /home/$(whoami)/data/*

# Check database tables
cd srcs   # from the repository root
export $(grep -v '^#' .env | xargs)
docker exec -it mariadb mysql -u $SQL_USER -p$SQL_PASSWORD -e "USE $SQL_DATABASE; SHOW TABLES;"

# Inspect a specific table (loads credentials from .env)
export $(grep -v '^#' .env | xargs) && docker exec -it mariadb mysql -u $SQL_USER -p$SQL_PASSWORD -e "SELECT * FROM <name_of_table>;" $SQL_DATABASE

# Remove all volumes (WARNING: deletes all data)
docker compose -f srcs/docker-compose.yml down -v
```

---

## Network Configuration

### Port Mapping

Only NGINX exposes ports to the host. WordPress and MariaDB are only accessible internally through the Docker network.

```yaml
# nginx in docker-compose.yml
ports:
  - "443:443"  # HOST_PORT:CONTAINER_PORT
```

> The format is always `HOST:CONTAINER`.

---

### Port Summary

| Service | Default Port | Exposed to Host | Where to Change |
|---|---|---|---|
| NGINX | `443` | ✅ Yes | `docker-compose.yml` + `nginx.conf` + WordPress URLs |
| WordPress (PHP-FPM) | `9000` | ❌ No | `www.conf` + `nginx.conf` |
| MariaDB | `3306` | ❌ No | `50-server.cnf` + `setup_wordpress.sh` |

---

### Changing Ports

**NGINX - change the host-side port:**

```yaml
# docker-compose.yml
ports:
  - "8080:443"
```

Then update WordPress URLs:

```bash
docker exec -it wordpress bash
wp option update siteurl 'https://dbajeux.42.fr:8080' --allow-root
wp option update home 'https://dbajeux.42.fr:8080' --allow-root
```

Verify:

```bash
docker exec nginx ss -tlnp | grep 8080
docker exec wordpress wp option get siteurl --allow-root
docker exec wordpress wp option get home --allow-root
```

---

**WordPress (PHP-FPM) - change the internal port:**

```ini
# www.conf
listen = 0.0.0.0:9001
```

Then update NGINX:

```nginx
# nginx.conf
fastcgi_pass wordpress:9001;
```

Verify:

```bash
docker exec nginx bash -c "echo > /dev/tcp/wordpress/9001" && echo "port reachable" || echo "port closed"
docker exec nginx curl -s telnet://wordpress:9001 #if infinity loop it's works 
```

---

**MariaDB - change the internal port:**

```ini
# 50-server.cnf
port = 3307
```

Then update the WordPress setup script:

```bash
# setup_wordpress.sh - update both the wait loop and the database host
until mysqladmin ping -h"mariadb" --port=3307 --user="$SQL_USER" --password="$SQL_PASSWORD" --silent
# ...
--dbhost="mariadb:3307"
```

Verify:

```bash
docker exec mariadb ss -tlnp | grep 3307
```

---

## Service Details

### NGINX Service

**Purpose:** HTTPS web server and reverse proxy

**Key files:**
- `requirements/nginx/Dockerfile`
- `requirements/nginx/conf/nginx.conf`
- `requirements/nginx/tools/setup_ssl.sh`

**Configuration highlights:**

```nginx
server {
    listen 443 ssl http2;

    server_name dbajeux.42.fr www.dbajeux.42.fr;   # replace with your login

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    root /var/www/html;
    index index.php index.html index.htm;

    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Useful commands:**

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

---

### WordPress Service

**Purpose:** PHP-FPM application server running WordPress

**Key files:**
- `requirements/wordpress/Dockerfile`
- `requirements/wordpress/conf/www.conf`
- `requirements/wordpress/tools/setup_wordpress.sh`

**Initialization tasks** (`setup_wordpress.sh`, only if `wp-config.php` does not exist):
1. Check that all required environment variables are set
2. Wait until MariaDB accepts connections
3. Download WordPress core with WP-CLI (`WP_VERSION` from `.env` - `6.4` in the template, `6.0` if unset - locale `fr_FR`)
4. Create `wp-config.php` with the database credentials
5. Install WordPress and create the administrator account
6. Create the secondary user with the `author` role
7. Fix file ownership for `www-data` and start `php-fpm8.2 -F` in the foreground

**Useful commands:**

```bash
# Check WordPress version
docker exec wordpress wp --info --allow-root
# List installed plugins
docker exec wordpress wp plugin list --allow-root
# Check database connection
docker exec wordpress wp db check --allow-root
# Update WordPress core
docker exec wordpress wp core update --allow-root
# Create a new post
docker exec wordpress wp post create --post_title="Hello" --post_content="World" --post_status=publish --allow-root
```

---

### MariaDB Service

**Purpose:** MySQL-compatible database server

**Key files:**
- `requirements/mariadb/Dockerfile`
- `requirements/mariadb/conf/50-server.cnf`
- `requirements/mariadb/tools/setup_mariadb.sh`

**Initialization tasks** (`setup_mariadb.sh`, on every start):
1. Check that all required environment variables are set
2. Start MariaDB temporarily and wait until it is ready
3. Set the root password
4. Create the WordPress database and user if they do not exist, and grant privileges
5. Shut down cleanly, then start `mysqld_safe` in the foreground

**Useful commands:**

```bash
# Connect to MySQL CLI
docker exec -it mariadb mysql -u root -p
# Show all databases
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"
# Show WordPress tables
docker exec mariadb mysql -u root -p wordpress -e "SHOW TABLES;"
```

---

## Debugging

### SSL/TLS Issues

```bash
# Test TLS connectivity
openssl s_client -connect login.42.fr:443 -tls1_2
openssl s_client -connect login.42.fr:443 -tls1_3

# Inspect certificate details
docker exec nginx openssl x509 -in /etc/nginx/ssl/nginx.crt -text -noout

# Verify NGINX configuration
docker exec nginx nginx -t
```

---

## Security Considerations

### SSL/TLS Configuration

**Self-signed certificate** (generated by `setup_ssl.sh` on first start):

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=BE/ST=Brussels/L=Brussels/O=42School/OU=student/CN=${DOMAIN_NAME}"
```

**Enforce TLS 1.2 / 1.3 in NGINX:**

```nginx
ssl_protocols TLSv1.2 TLSv1.3;   # configured in nginx.conf

# Possible hardening (not enabled in this project):
# ssl_prefer_server_ciphers on;
# ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
```

### Network Security

```yaml
networks:
  inception:
    driver: bridge

ports:
  - "443:443"  # Only HTTPS exposed
```

---

## Data Storage and Persistence

### Storage Locations

**On the host machine:**

```
/home/login/data/
├── wordpress/          # WordPress installation files
│   ├── wp-content/
│   ├── wp-config.php
│   └── ...
└── mariadb/            # MariaDB database files
    ├── mysql/          # MariaDB system database
    ├── wordpress/
    └── ...
```

**Inside containers:**

| Service | Path |
|---|---|
| WordPress | `/var/www/html/` |
| MariaDB | `/var/lib/mysql/` |
| NGINX | No persistent data (config baked into image) |

---

## Useful Commands Reference

### Project Management

```bash
make              # Build and start everything
make down         # Stop services
make fclean       # Clean everything (destructive)
make re           # Full rebuild from scratch (destructive)
```

### Docker Compose

```bash
docker compose -f srcs/docker-compose.yml ps               # List services
docker compose -f srcs/docker-compose.yml logs -f          # Follow all logs
docker compose -f srcs/docker-compose.yml restart nginx    # Restart a service
docker compose -f srcs/docker-compose.yml exec wordpress sh # Enter a container
```

### Container Management

```bash
docker ps               # List running containers
docker ps -a            # List all containers
docker logs <name>      # View container logs
docker exec -it <name> sh  # Enter a container
docker inspect <name>   # Detailed container info
```

### Volume Management

```bash
docker volume ls                       # List volumes
docker volume inspect <name>           # Volume details
du -sh /home/$(whoami)/data/*          # Check data size on host
```

### Network Management

```bash
docker network ls                              # List networks
docker network inspect srcs_inception         # Network details (Compose project name = srcs)
```

### System Cleanup

```bash
docker system df           # Show disk usage
docker system prune -a     # Remove all unused resources
```

---

## Known Limitations and Possible Improvements

This repository keeps the project as it was designed and evaluated. These are the points I would improve next:

### Base image migration (Debian 11 → 12)

The project was originally built on Debian 11 (bullseye). Debian 11 reached its end of life in August 2026 and its security repository was removed from `deb.debian.org`, so `apt-get install` failed with `404 Not Found` errors. The images were moved to **Debian 12 (bookworm)**, which also required switching from PHP 7.4 to **PHP 8.2** (`php8.2-fpm`, `/etc/php/8.2/fpm/pool.d/www.conf`, `php-fpm8.2 -F`) and pinning a WordPress version compatible with PHP 8.2 through `WP_VERSION`.

### MariaDB initialization runs on every start

`setup_mariadb.sh` runs the initialization SQL at each container start. On the first start, root has no password yet and everything succeeds. On later starts (`make down` / `make up`, reboot), `mysql` connects without a password and is rejected, so the logs show an `Access denied` error before MariaDB starts normally - the service and the data are not affected.

**Improvement:** only run the initialization when the database does not exist yet, as the WordPress and NGINX scripts already do:

```bash
if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    # start MariaDB, set the root password, create the database and user, shut down
fi
exec mysqld_safe
```

### Other ideas

- Use **Docker secrets** for passwords instead of environment variables
- Add **health checks** in `docker-compose.yml` so `depends_on` waits for services to be *ready*, not only started
- Read the NGINX `server_name` from `DOMAIN_NAME` instead of hard-coding it in `nginx.conf`

---

**Project:** 42 Inception - Developer Reference