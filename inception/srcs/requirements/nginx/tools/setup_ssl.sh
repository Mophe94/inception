#!/bin/bash

# Message pour indiquer que la configuration SSL commence
echo "Setting up SSL certificates..."

# Vérifie que la variable DOMAIN_NAME est définie
if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Missing required environment variable DOMAIN_NAME."
    exit 1
fi

# Crée le dossier pour stocker les certificats si nécessaire
mkdir -p /etc/nginx/ssl

# Vérifie si le certificat existe déjà pour éviter de le recréer
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating self-signed SSL certificate..."

    # Génère un certificat SSL auto-signé valable 1 an
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=BE/ST=Brussels/L=Brussels/O=42School/OU=student/CN=${DOMAIN_NAME}"

    echo "SSL certificate generated successfully."
else
    echo "SSL certificate already exists, skipping generation."
fi

# Démarre NGINX en avant-plan (obligatoire pour Docker)
echo "Starting NGINX..."
exec nginx -g "daemon off;"

