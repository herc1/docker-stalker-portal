#!/bin/bash

echo "If you are using external DB please do the following inside the container (docker exec -it stalker-portal bash):"
echo "1. If the DB contents do not match the version of the container - run: cd /var/www/stalker_portal/deploy/ && phing"
echo "2. Load the TZ info once: mysql_tzinfo_to_sql /usr/share/zoneinfo 2>/dev/null | mysql -u root -p mysql -h DB_HOST"
echo "3. On the external DB set max_allowed_packet = 32M in /etc/mysql/my.cnf"

cp -f /opt/conf/nginx/*.conf /etc/nginx/conf.d/
cp -f /opt/conf/apache2/*.conf /etc/apache2/sites-available/
cp -f /opt/conf/apache2/conf-available/*.conf /etc/apache2/conf-available/
cp -f /opt/conf/custom.ini /var/www/stalker_portal/server/

if [ -n ${TZ} ]; then
 ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

if [ $(ls /var/lib/mysql|wc -l) -eq 0 ]
then
 echo "Copy default DB schema to /var/lib/mysql"
 cp -rf /root/mysql_default/* /var/lib/mysql/
 chown -R mysql:mysql /var/lib/mysql
fi

service mysql start
if [ $(ls /opt/conf/mysql/*.sql | wc -l) -eq 1 ]
then
 echo "Restoring dump to stalker_db database..."
 sqldump=$(ls -t /opt/conf/mysql/*.sql|head -n 1)
 mysql -u stalker -p1 -e 'drop database stalker_db;'
 mysql -u stalker -p1 -e 'create database stalker_db;'
 mysql -u stalker -p1 stalker_db < $sqldump
 rm -f $sqldump
fi

services=(mysql memcached cron apache2 nginx)
while true; do
 for service in ${services[@]}; do
  if [ $(pgrep $service | wc -l) -eq 0 ]
  then
   echo "Service $service is not running. Starting"
   if [ "$service" != "cron" ]
   then
    service $service start
   else
    cron
   fi
  fi
 done
 sleep 5
done
