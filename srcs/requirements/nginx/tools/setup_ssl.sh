#!/bin/bash

# Message to indicate that SSL configuration is starting
echo "Setting up SSL certificates..."

# Checks that the DOMAIN_NAME variable is defined
if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Missing required environment variable DOMAIN_NAME."
    exit 1
fi

# Creates the directory to store the certificates if necessary
mkdir -p /etc/nginx/ssl

# Checks if the certificate already exists to avoid recreating it
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating self-signed SSL certificate..."

    # Generates a self-signed SSL certificate valid for 1 year
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=BE/ST=Brussels/L=Brussels/O=42School/OU=student/CN=${DOMAIN_NAME}"

    echo "SSL certificate generated successfully."
else
    echo "SSL certificate already exists, skipping generation."
fi

# Starts NGINX in the foreground (required for Docker)
echo "Starting NGINX..."
exec nginx -g "daemon off;"