#!/bin/bash

cp -f /opt/conf/nginx/*.conf /etc/nginx/conf.d/
cp -f /opt/conf/apache2/*.conf /etc/apache2/sites-available/
cp -f /opt/conf/apache2/conf-available/*.conf /etc/apache2/conf-available/
cp -f /opt/conf/custom.ini /var/www/stalker_portal/server/

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

if [ $(ls /var/www | wc -l) -eq 0 ]
then
 echo "/var/www is empty. Filling."
 cp -rf /root/www/* /var/www/
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
