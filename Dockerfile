FROM ubuntu:20.04

ENV UBUNTU_CODENAME="focal"
ENV PHP_VERSION="8.0"
ENV DEBIAN_FRONTEND="noninteractive"
ENV APACHE_RUN_DIR="/etc/apache2"
ENV APACHE_PID_FILE="/var/run/apache2/apache2"
ENV APACHE_RUN_USER="www-data"
ENV APACHE_RUN_GROUP="www-data"
ENV APACHE_LOG_DIR="/var/log/apache2"

#####
# Install base
#####
RUN apt-get update 
RUN apt-get install --assume-yes --no-install-recommends --no-install-suggests \ 
    apache2 \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    ssl-cert
RUN make-ssl-cert generate-default-snakeoil --force-overwrite
COPY etc/apache2/sites-available /etc/apache2/sites-available
COPY etc/apache2/sites-enabled /etc/apache2/sites-enabled

#####
# Install PHP
#####
RUN echo "deb http://ppa.launchpad.net/ondrej/apache2/ubuntu ${UBUNTU_CODENAME} main" >> /etc/apt/sources.list
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu ${UBUNTU_CODENAME} main" >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C
RUN apt-get update 
RUN apt-get install --assume-yes --no-install-recommends --no-install-suggests \ 
    libapache2-mod-php${PHP_VERSION} \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-bz2 \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dev \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-msgpack \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-pdo-pgsql \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-sockets \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-yaml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-redis 
    

RUN echo "TLS_REQCERT  allow" >> /etc/ldap/ldap.conf 

RUN git clone --branch "master" https://github.com/q2a/question2answer.git \
 && git clone https://github.com/amiyasahu/Donut.git \
 && git clone https://github.com/ganbox/qa-filter.git /question2answer/qa-plugin/qa-filter \
 && git clone https://github.com/NoahY/q2a-poll.git /question2answer/qa-plugin/qa-poll \
 && git clone https://github.com/svivian/q2a-user-activity-plus.git /question2answer/qa-plugin/qa-user-activity \
 && git clone https://github.com/zakkak/qa-ldap-login.git /question2answer/qa-plugin/qa-ldap-login \
 && git clone https://github.com/NoahY/q2a-history.git /question2answer/qa-plugin/qa-user-history \
 && git clone https://github.com/NoahY/q2a-log-tags.git /question2answer/qa-plugin/qa-log-tags \
 && git clone https://github.com/dunse/qa-category-email-notifications.git /question2answer/qa-plugin/qa-email-notification \
 && git clone https://github.com/pupi1985/q2a-wiki /question2answer/qa-plugin/q2a-wiki 

COPY qa-config.php /question2answer/qa-config.php

RUN rm -fR /var/www/html \
 && ln -s /question2answer /var/www/html \
 && ln -s /Donut/qa-plugin/Donut-admin /question2answer/qa-plugin \
 && ln -s /Donut/qa-theme/Donut-theme /question2answer/qa-theme

# Put require into the login page
RUN sed -i "s/^\(.*\)require_once QA_INCLUDE_DIR \. 'db\/selects\.php';/\1require_once QA_INCLUDE_DIR \. 'db\/selects\.php';\\n\1require_once QA_INCLUDE_DIR \. '\.\.\/qa-plugin\/qa-ldap-login\/qa-ldap-process\.php';/" /var/www/html/qa-include/pages/login.php

EXPOSE 80
EXPOSE 443

STOPSIGNAL SIGWINCH

RUN a2enmod ssl

CMD ["apache2", "-DFOREGROUND"]