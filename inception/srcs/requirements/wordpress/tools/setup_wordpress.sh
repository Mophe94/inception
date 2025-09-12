#!/bin/bash

# Vérifie que toutes les variables d'environnement nécessaires sont définies
if [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ] || \
   [ -z "$SQL_PASSWORD" ] || [ -z "$DOMAIN_NAME" ] || \
   [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || \
   [ -z "$WP_ADMIN_EMAIL" ] || [ -z "$WP_USER" ] || \
   [ -z "$WP_USER_EMAIL" ] || [ -z "$WP_USER_PASSWORD" ]; then
    echo "Error: Missing required environment variables."
    exit 1
fi

# Vérifie que la base de données est prête à accepter les connexions
MAX_RETRIES=30
COUNT=0
until mysqladmin ping -h"mariadb" -u"$SQL_USER" -p"$SQL_PASSWORD" --silent || [ $COUNT -eq $MAX_RETRIES ]; do
    echo "Waiting for MariaDB... attempt $((COUNT + 1))/$MAX_RETRIES"
    sleep 2
    COUNT=$((COUNT + 1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "Error: MariaDB did not start after $MAX_RETRIES attempts."
    exit 1
fi

# Installe WordPress seulement si wp-config.php n'existe pas
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --version="${WP_VERSION:-6.0}" --locale=fr_FR --allow-root

    echo "Creating wp-config.php..."
    wp config create --allow-root \
        --dbname="${SQL_DATABASE}" \
        --dbuser="${SQL_USER}" \
        --dbpass="${SQL_PASSWORD}" \
        --dbhost="mariadb:3306"

    echo "Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception42" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    echo "Creating user ${WP_USER}..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root
else
    echo "WordPress is already installed. Skipping installation."
fi

# Création du dossier requis par PHP-FPM si besoin
mkdir -p /run/php

# Droits d'accès pour NGINX/PHP
chown -R www-data:www-data .
chmod -R 755 .

# Démarrage de PHP-FPM en foreground
exec php-fpm7.4 -F

