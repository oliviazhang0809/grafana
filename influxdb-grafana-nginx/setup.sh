#!/bin/bash

# Basic Setup
INFLUXDB_VER=influxdb-0.8.5-1
INFLUXDB_PKG=$INFLUXDB_VER.x86_64.rpm
INFLUXDB_URL=http://s3.amazonaws.com/influxdb/$INFLUXDB_PKG
GRAFANA_VER=grafana-1.8.1
GRAFANA_PKG=$GRAFANA_VER.tar.gz
GRAFANA_URL=http://grafanarel.s3.amazonaws.com/$GRAFANA_PKG
NGINX_VER=nginx-release-centos-6-0.el6.ngx.noarch
NGINX_PKG=$NGINX_VER.rpm
NGINX_URL=http://nginx.org/packages/centos/6/noarch/RPMS/$NGINX_PKG
DB_TO_OPEN="test1"
MY_HOST="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"


echo ""
echo "Warning: the hostname is default set as $MY_HOST."
echo ""
sleep 5

yum -y update
yum -y install libuuid uuid python-setuptools python-devel gcc git

echo "Downloading and installing influxdb."
wget $INFLUXDB_URL
rpm -ivh $INFLUXDB_PKG
/etc/init.d/influxdb start

echo "Downloading and installing Grafana."
wget $GRAFANA_URL
tar xvfz $GRAFANA_PKG

echo "Downloading and installing nginx."
yum -y install $NGINX_URL
yum -y install nginx
mv /etc/nginx/conf.d/default.conf{,.disabled}

echo "Creating Influxdb database $DB_TO_OPEN."
curl -s "http://$MY_HOST:8086/db?u=root&p=root" -d "{\"name\": \"$DB_TO_OPEN\"}"

echo "Configuring Grafana."
wget https://raw.githubusercontent.com/oliviazhang0809/chowder/master/influxdb-grafana-nginx/config.js -O $GRAFANA_VER/config.js --no-check-certificate
sed -i "s|HOST_NAME|$MY_HOST|g" $GRAFANA_VER/config.js
sed -i "s|DATABASE_NAME|$DB_TO_OPEN|g" $GRAFANA_VER/config.js
mkdir -p /var/www/{public,private,log,backup}
mv $GRAFANA_VER /var/www/public/grafana

echo "Configuring Nginx."
rm /etc/nginx/nginx.conf
wget https://raw.githubusercontent.com/oliviazhang0809/chowder/master/influxdb-grafana-nginx/nginx.conf -O /etc/nginx/nginx.conf --no-check-certificate
nginx

echo "Downloading sine wave generation program."
curl -s https://gist.githubusercontent.com/otoolep/3d5741e680bf76021f77/raw/1d81a1ad4771659b008b9c346b4dd20ef1b72536/sine.py >sine.py

echo -e "Configuration complete."
