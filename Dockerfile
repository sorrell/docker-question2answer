FROM intxlog/apache

RUN echo "deb http://ppa.launchpad.net/ondrej/apache2/ubuntu bionic main" >> /etc/apt/sources.list
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C

RUN apt-get update \
    && apt-get install -y php7.3-cli php7.3-mysql php7.3-ldap vim apache2 

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
    
RUN sed -i "s/^<?php/<\?php\\nrequire_once QA_INCLUDE_DIR \. '\.\.\/qa-plugin\/qa-ldap-login\/qa-ldap-process\.php';/" /var/www/html/qa-include/pages/login.php

EXPOSE 80

STOPSIGNAL SIGWINCH

CMD ["apache2", "-DFOREGROUND"]