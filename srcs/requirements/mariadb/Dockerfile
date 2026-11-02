# We use the Debian 12 image as a starting point
FROM debian:bullseye

# Install MariaDB
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

# Prepare the required directories with the correct permissions
RUN mkdir -p /var/lib/mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Copy the configuration file we set up
# If this file is modified it's because these are the official files for
# configuring the MariaDB server
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy the script we set up to initialize the database
COPY tools/setup_mariadb.sh /setup.sh

RUN chmod +x /setup.sh

ENTRYPOINT ["bash","/setup.sh"]