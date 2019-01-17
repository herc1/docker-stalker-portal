FROM ubuntu:14.04

ENV stalker_version 520

ENV stalker_zip stalker_portal-5.2.0.zip

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get -y update 

RUN apt-get -y upgrade

RUN apt-get install -y -u apache2 nginx memcached mysql-server php5 php5-mysql php-pear nodejs upstart npm php5-mcrypt openssh-client expect mysql-client

RUN apt-get install -y unzip

RUN npm config set strict-ssl false

RUN npm install -g npm@2.15.11

RUN ln -s /usr/bin/nodejs /usr/bin/node

RUN pear channel-discover pear.phing.info

RUN pear install -Z phing/phing

RUN rm -f /etc/nginx/sites-available/default

RUN echo "max_allowed_packet = 32M" >> /etc/mysql/my.cnf

RUN php5enmod mcrypt

RUN sed -i 's/Listen 80/Listen 88/' /etc/apache2/ports.conf

RUN echo "short_open_tag = On" >> /etc/php5/apache2/php.ini

RUN a2enmod rewrite

RUN a2enmod remoteip

RUN service mysql start && mysql -u root -e "GRANT ALL PRIVILEGES ON stalker_db.* TO stalker@localhost IDENTIFIED BY '1' WITH GRANT OPTION;" && mysql -u root -e "GRANT ALL PRIVILEGES ON stalker_db.* TO root@localhost IDENTIFIED BY '1' WITH GRANT OPTION;"

RUN for i in ru_RU.utf8 en_GB.utf8 uk_UA.utf8 pl_PL.utf8 el_GR.utf8 nl_NL.utf8 it_IT.utf8 de_DE.utf8 sk_SK.utf8 es_ES.utf8 bg_BG.utf8 en_IE.utf8; do locale-gen $i; done

RUN dpkg-reconfigure locales

COPY ${stalker_zip} /

RUN unzip ${stalker_zip} -d stalker_portal

RUN mv stalker_portal/* /var/www/stalker_portal

RUN rm -rf stalker_portal

RUN rm -rf ${stalker_zip}

RUN echo ${stalker_version} > stalker_version

COPY index.html /var/www/

COPY locale/ /var/www/stalker_portal/server/locale/

RUN service mysql start && service memcached start && cd /var/www/stalker_portal/deploy/ && expect -c 'set timeout 9000; spawn phing; expect "Enter password:"; send "1\r"; expect eof;'

RUN mkdir /root/mysql_default && cp -rf /var/lib/mysql/* /root/mysql_default/

COPY conf/nginx/*.conf /etc/nginx/conf.d/

COPY conf/apache2/*.conf /etc/apache2/sites-available/

COPY conf/apache2/conf-available/*.conf /etc/apache2/conf-available/

RUN a2enconf remoteip

COPY entrypoint.sh /

EXPOSE 88

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]