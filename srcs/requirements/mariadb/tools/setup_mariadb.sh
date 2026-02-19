#!/bin/bash

# Checks that all required environment variables are defined
if [ -z "$SQL_ROOT_PASSWORD" ] || [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ] || [ -z "$SQL_PASSWORD" ]; then
    echo "Error: Missing required environment variables."
    exit 1
fi

# Starts MariaDB in service mode for initialization
service mariadb start

# Wait for MariaDB to be ready to accept connections
MAX_RETRIES=30
COUNT=0
until mysqladmin ping --silent || [ $COUNT -eq $MAX_RETRIES ]; do
    sleep 2
    COUNT=$((COUNT + 1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "Error: MariaDB did not start after $MAX_RETRIES attempts."
    exit 1
fi

# Merges root configuration + database and user creation into a single execution
mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Clean shutdown for restart in foreground mode
mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
sleep 2

# Start MariaDB in foreground mode for Docker
exec mysqld_safe