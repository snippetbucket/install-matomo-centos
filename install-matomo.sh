#!/bin/bash 

#Colours
#RED="\033[31m"
#GREEN="\033[32m"
#BLUE="\033[34m"
#RESET="\033[0m"

#my prep
echo -e "\033[32mInstall some of my favorite general packages\033[0m"
yum update -y
yum install -y vim wget

#install required packages
echo -e "\033[32mNow packages you need for Matomo\033[0m"
yum install -y centos-release-scl
yum install -y rh-php71-php rh-php71-php-mysqlnd
yum install -y rh-php71-php-mbstring rh-php71-php-dom rh-php71-php-xml rh-php71-php-gd
yum install -y sclo-php71-php-pecl-geoip rh-php71-php-devel
yum install -y httpd24-httpd httpd24-httpd httpd24-mod_ssl httpd24-mod_proxy_html
yum install -y mariadb-server mariadb

#copy your ssl certificates
mkdir -pv /opt/rh/httpd24/root/var/www/logs/
echo -e "For SSL certificates to work properly you need to copy the certificate files. I assume you have them already somewhere accessible on the net."
read -p "\033[32mEnter the source location for your ssl certificate key file (doc.diamondkey.com:/etc/ssl/certs/star_diamondkey_com.key):" ssl_key
ssl_key=${ssl_key:-"doc.diamondkey.com:/etc/ssl/certs/star_diamondkey_com.key"}
read -p "Enter the source location for your ssl certificates (doc.diamondkey.com:/etc/ssl/certs/star_diamondkey_com.crt):" ssl_crt
ssl_crt= ${ssl_crt:-"doc.diamondkey.com:/etc/ssl/certs/star_diamondkey_com.crt"}
scp -v $ssl_key /etc/ssl/certs/
scp -v $ssl_crt /etc/ssl/certs/


echo "\033[32mWe are going to run the servers and services\033[0m"
systemctl enable httpd24-httpd mariadb
systemctl start mariadb
mysql_secure_installation
systemctl start httpd24-httpd

mkdir /opt/matomo
cd /opt/matomo
wget https://builds.piwik.org/piwik.tar.gz
tar -xvf piwik.tar.gz
cp -r piwik /opt/rh/httpd24/root/var/www/html/matomo
cp -v CONF/httpd/matomo.conf /opt/rh/httpd24/root/etc/httpd/conf.d/

#Selinuc config mode update to permissive

echo -e "\033[32mFor apache to work properly with ssl, change the mode to permissive"
echo -e "Press any key to update the config file or Ctrl-c to exit."
read -n1 -p
echo
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/sysconfig/selinux && echo SUCCESS || echo FAILURE

chown -R apache:apache /opt/rh/httpd24/root/var/www/html/matomo
chmod -R 0755 /opt/rh/httpd24/root/var/www/html/matomo/tmp

echo "now time to prepare the database. Keep record of your answers to next step questions. You will need them later when starting your server on GUI"

read -sp "What is your MariaDB root password: " db_root_pwd
echo
read -p "Enter the Matomo user name you want to create: (matomo_user) " matomo_user
matomo_user=${matomo_user:-matomo_user}
read -sp "Enter the new Matomo user password: " matomo_usr_pwd
echo
read -p "Enter the Matomo database you want to create (matomo_db) : " matomo_db
matomo_db=${matomo_db:-matomo_db}
mysql -u root -p$db_root_pwd -ve"CREATE DATABASE $matomo_db;"
mysql -u root -p$db_root_pwd -ve"CREATE USER '$matomo_user'@'localhost' IDENTIFIED BY '$matomo_usr_pwd';"
mysql -u root -p$db_root_pwd -ve"GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON $matomo_db.* TO '$matomo_user'@'localhost';"

echo -e "\033[32mGreat!!! Matomo installation completed successfully."
echo "Your system needs to be rebooted before you can continue to setup your system from GUI."
echo "After restart you need to complete the setup from a web browser. Navigate to: https://your-server-name.com"
echo -e "\033[32mPress Any Key to reboot the system."
read -n1 -p
echo
reboot

