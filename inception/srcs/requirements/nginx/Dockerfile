# Utilise Debian 13 comme image de base
FROM debian:13

# Met à jour les paquets, installe NGINX et OpenSSL en une seule couche et nettoie le cache apt
RUN apt update \
    && apt install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/*

# Supprime les fichiers de configuration par défaut de NGINX pour éviter les conflits
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

# Copie le fichier de configuration NGINX personnalisé dans le conteneur
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copie le script de configuration SSL et le rend exécutable
COPY tools/setup_ssl.sh /setup.sh
RUN chmod +x /setup.sh

# Donne les droits en lecture/écriture/exécution au propriétaire et lecture/exécution aux autres
RUN chmod -R 755 /var/www/html

# Change le propriétaire des fichiers en 'www-data' (utilisé par NGINX)
RUN chown -R www-data:www-data /var/www/html

# Déclare le port HTTPS comme exposé
EXPOSE 443

# Utilise le script de configuration SSL comme entrypoint
ENTRYPOINT ["bash", "/setup.sh"]

