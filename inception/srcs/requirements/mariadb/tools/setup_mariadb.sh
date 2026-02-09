#!/bin/bash

# Vérifie que toutes les variables d'environnement nécessaires sont définies
if [ -z "$SQL_ROOT_PASSWORD" ] || [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ] || [ -z "$SQL_PASSWORD" ]; then
    echo "Error: Missing required environment variables."
    exit 1
fi

# Démarre MariaDB en mode service pour initialisation
service mariadb start

# Attendre que MariaDB soit prêt à accepter les connexions
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

# Fusionne la configuration root + création base et utilisateur en une seule exécution
mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Arrêt propre pour redémarrage en mode foreground
mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
sleep 2

# Démarrage de MariaDB en mode foreground pour Docker
exec mysqld_safe

