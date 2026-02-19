FROM debian:bullseye

RUN apt update \
	&& apt install -y wget \
	php7.4-fpm php7.4-mysql \
    	mariadb-client \ 
	&& rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Here we install WP-CLI which gives us a command line interface
# it allows us to administrate WordPress without going through the Web interface
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp \
&& chmod +x /usr/local/bin/wp

# Creates the root directory for WordPress
RUN mkdir -p /var/www/html

# Copies the WordPress installation script
COPY tools/setup_wordpress.sh /setup.sh

# Makes the script executable
RUN chmod +x /setup.sh

# Declares port 9000 used by PHP-FPM
EXPOSE 9000

# Sets the default working directory.
# Important so that our script installs WordPress in the right place
WORKDIR /var/www/html

# Runs the automatic installation when the container starts
ENTRYPOINT ["bash", "/setup.sh"]