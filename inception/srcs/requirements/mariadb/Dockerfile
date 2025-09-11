#on prend l'image Debian 12 comme depart
FROM debian:12

# Installer MariaDB
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

# Préparer les dossiers nécessaires avec les bonnes permissions
RUN mkdir -p /var/lib/mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

#copy du fichier conf que l'on a mis en place 
#si on modifie se fichier ses parce que se sont les fichier officiel pour config
#serveur Mariadb
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

#copy du script que l'on a mis en place pour setup la db
COPY tools/setup_mariadb.sh /setup.sh

RUN chmod +x /setup.sh

ENTRYPOINT ["bash","/setup.sh"]


