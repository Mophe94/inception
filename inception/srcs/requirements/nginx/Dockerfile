#on utilise Debian12 comme base
FROM debian:12

# on met a jour les paquets && on installe nginx && on viens vider le cache de apt
RUN apt update \
	&& apt install -y nginx \
	&& rm -rf /var/lib/apt/lists/*

#OpenSSl est le moteur cryptographique qui permet de gerer les certificats SSL/TLS : sans lui on ne pourrait pas servir le site en HTTPS
RUN apt update \
	&& apt install openssl -y \
	&& rm -rf /var/lib/apt/lists/*

#on retire les config par default de NGINX pour eviter les conflit
RUN rm -f /etc/nginx/sites-enabled/default
RUN rm -f /etc/nginx/sites-available/default

#on vient prendre le fichier nginx.conf et on va le placer dans /etc/nginx au moment du build
COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/setup_ssl.sh /setup.sh
RUN chmod +x /setup.sh

# Donne les droits en lecture/écriture/exécution pour le propriétaire, et lecture/exécution pour les autres
# sur tous les fichiers/dossiers du répertoire /var/www/html
RUN chmod -R 755 /var/www/html

# Change le propriétaire des fichiers du dossier /var/www/html en 'www-data'
# (l'utilisateur utilisé par NGINX pour exécuter les processus web)
RUN chown -R www-data:www-data /var/www/html

# Déclare le port 443 comme exposé (HTTPS)
# Cela indique à Docker que ce port sera utilisé par le conteneur à l'exécution
EXPOSE 443

# Utilise le script bash comme point d’entrée (entrypoint)
ENTRYPOINT ["bash", "/setup.sh"]
