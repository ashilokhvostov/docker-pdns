#!/bin/bash
MYSQL_HOST=${DB_PORT_33060_TCP_ADDR:-db}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${DB_ENV_MYSQL_ROOT_PASSWORD}
MYSQL_DB=${MYSQL_DB:-pdns}
PDNS_ALLOW_AXFR_IPS=${PDNS_ALLOW_AXFR_IPS:-127.0.0.1}
PDNS_MASTER=${PDNS_MASTER:-yes}
PDNS_SLAVE=${PDNS_SLAVE:-no}
PDNS_CACHE_TTL=${PDNS_CACHE_TTL:-20}
PDNS_DISTRIBUTOR_THREADS=${PDNS_DISTRIBUTOR_THREADS:-3}
POWERADMIN_HOSTMASTER=${POWERADMIN_HOSTMASTER:-}
POWERADMIN_NS1=${POWERADMIN_NS1:-}
POWERADMIN_NS2=${POWERADMIN_NS2:-}
API_KEY=${API_KEY:-shifthappens}

until nc -z ${MYSQL_HOST} ${MYSQL_PORT}; do
    echo "$(date) - waiting for mysql..."
    sleep 1
done

if mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} --host=${MYSQL_HOST} "${MYSQL_DB}" >/dev/null 2>&1 </dev/null
then
	echo "Database ${MYSQL_DB} already exists"
else
	mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} --host=${MYSQL_HOST} -e "CREATE DATABASE ${MYSQL_DB}"
	mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} --host=${MYSQL_HOST} ${MYSQL_DB} < /pdns.sql
	mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} --host=${MYSQL_HOST} ${MYSQL_DB} < /poweradmin.sql
	rm /pdns.sql /poweradmin.sql
fi

### SUPERVISOR
sed -i "s/{{MYSQL_HOST}}/${MYSQL_HOST}/" /etc/powerdns/pdns.d/pdns.local.gmysql.conf
sed -i "s/{{MYSQL_PORT}}/${MYSQL_PORT}/" /etc/powerdns/pdns.d/pdns.local.gmysql.conf
sed -i "s/{{MYSQL_USER}}/${MYSQL_USER}/" /etc/powerdns/pdns.d/pdns.local.gmysql.conf
sed -i "s/{{MYSQL_PASSWORD}}/${MYSQL_PASSWORD}/" /etc/powerdns/pdns.d/pdns.local.gmysql.conf
sed -i "s/{{MYSQL_DB}}/${MYSQL_DB}/" /etc/powerdns/pdns.d/pdns.local.gmysql.conf

sed -i "s/{{PDNS_ALLOW_AXFR_IPS}}/${PDNS_ALLOW_AXFR_IPS}/" /etc/powerdns/pdns.conf
sed -i "s/{{PDNS_MASTER}}/${PDNS_MASTER}/" /etc/powerdns/pdns.conf
sed -i "s/{{PDNS_SLAVE}}/${PDNS_SLAVE}/" /etc/powerdns/pdns.conf
sed -i "s/{{PDNS_CACHE_TTL}}/${PDNS_CACHE_TTL}/" /etc/powerdns/pdns.conf
sed -i "s/{{PDNS_DISTRIBUTOR_THREADS}}/${PDNS_DISTRIBUTOR_THREADS}/" /etc/powerdns/pdns.conf
sed -i "s/{{API_KEY}}/${API_KEY}/" /etc/powerdns/pdns.conf

### POWERADMIN
sed -i "s/{{MYSQL_HOST}}/${MYSQL_HOST}/" /var/www/html/inc/config.inc.php
sed -i "s/{{MYSQL_PORT}}/${MYSQL_PORT}/" /var/www/html/inc/config.inc.php
sed -i "s/{{MYSQL_USER}}/${MYSQL_USER}/" /var/www/html/inc/config.inc.php
sed -i "s/{{MYSQL_PASSWORD}}/${MYSQL_PASSWORD}/" /var/www/html/inc/config.inc.php
sed -i "s/{{MYSQL_DB}}/${MYSQL_DB}/" /var/www/html/inc/config.inc.php
sed -i "s/{{POWERADMIN_HOSTMASTER}}/${POWERADMIN_HOSTMASTER}/" /var/www/html/inc/config.inc.php
sed -i "s/{{POWERADMIN_NS1}}/${POWERADMIN_NS1}/" /var/www/html/inc/config.inc.php
sed -i "s/{{POWERADMIN_NS2}}/${POWERADMIN_NS2}/" /var/www/html/inc/config.inc.php

mkdir -p /run/php
rm /etc/powerdns/pdns.d/bind.conf
exec /usr/bin/supervisord

