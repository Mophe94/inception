FROM debian:bullseye

# Updates packages, installs NGINX and OpenSSL in a single layer and cleans the apt cache
RUN apt update \
    && apt install -y nginx openssl \
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