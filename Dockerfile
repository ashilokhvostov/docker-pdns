FROM ubuntu:18.04
MAINTAINER Shilokhvostov Alexander <ashilokhvostov@tradeshift.com>

COPY assets/apt/preferences.d/pdns /etc/apt/preferences.d/pdns

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y curl \
    software-properties-common

RUN add-apt-repository -y ppa:ondrej/php

RUN apt-get update && apt-get install -y \
	wget \
	git \
	supervisor \
	mysql-client \
	nginx \
	netcat \
	php5.6-fpm \
	php5.6-mcrypt \
	php5.6-mysql \
	pdns-server \
	pdns-backend-mysql \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

### PDNS ###

#RUN cd /tmp && wget https://downloads.powerdns.com/releases/deb/pdns-static_${VERSION}_amd64.deb && dpkg -i pdns-static_${VERSION}_amd64.deb && rm pdns-static_${VERSION}_amd64.deb
#RUN useradd --system pdns

COPY assets/nginx/nginx.conf /etc/nginx/nginx.conf
COPY assets/nginx/vhost.conf /etc/nginx/sites-enabled/vhost.conf
COPY assets/nginx/fastcgi_params /etc/nginx/fastcgi_params

COPY assets/php/php.ini /etc/php/5.6/fpm/php.ini
COPY assets/php/php-cli.ini /etc/php/5.6/cli/php.ini

COPY assets/pdns/pdns.conf /etc/powerdns/pdns.conf
COPY assets/pdns/pdns.d/ /etc/powerdns/pdns.d/
COPY assets/mysql/pdns.sql /pdns.sql

### PHP/Nginx ###
RUN rm /etc/nginx/sites-enabled/default
RUN phpenmod mcrypt
RUN mkdir -p /var/www/html/ \
	&& cd /var/www/html \
	&& rm -rf ./* \
	&& git clone https://github.com/poweradmin/poweradmin.git . \
	&& git checkout 772946ad40c765fece19aafbefd04fa23745e8ec \
	&& rm -R /var/www/html/install

COPY assets/poweradmin/config.inc.php /var/www/html/inc/config.inc.php
COPY assets/mysql/poweradmin.sql /poweradmin.sql
RUN chown -R www-data:www-data /var/www/html

### SUPERVISOR ###
COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh

EXPOSE 53 80 81
EXPOSE 53/udp

CMD ["/bin/bash", "/start.sh"]
