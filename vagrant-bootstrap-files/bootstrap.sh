#!/usr/bin/env bash

# read config file

file='/vagrant/vagrant-bootstrap-files/bootstrap.cfg'
file_secured='/tmp/bootstrap.cfg'

if egrep -q -v '^#|^[^ ]*=[^;]*' "$file"; then
  egrep '^#|^[^ ]*=[^;&]*'  "$file" > "$file_secured"
  file="$file_secured"
fi

. "$file"

# disable queries for user manual interactions

export DEBIAN_FRONTEND=noninteractive

# update packages

apt-get update -q

# update time zone

echo "$TIME_ZONE" > /etc/timezone

dpkg-reconfigure -f noninteractive tzdata

# vim

apt-get install -q -y vim

# apache

apt-get install -q -y apache2
apt-get install -q -y apache2.2-common

a2enmod rewrite headers

# php

apt-get install -q -y php5
apt-get install -q -y libapache2-mod-php5
apt-get install -q -y php5-curl php5-gd php5-mcrypt php5-mysqlnd php-soap php5-xdebug

service apache2 restart

# mysql

debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_USER_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_USER_PASSWORD"

apt-get install -q -y mysql-server-5.5

# sync vagrant folder with apache root folder

dir='/vagrant/www'

if [ ! -d "$dir" ]; then
  mkdir "$dir"
fi

if [ ! -L /var/www/html ]; then
  rm -rf /var/www/html
  ln -fs "$dir" /var/www/html
fi

# go to www

cd "$dir"

# phpinfo script

file='info.php'

if [ ! -f "$file" ]; then
  echo '<?php phpinfo();' > "$file"
fi

# opcache gui script

file='opcache.php'

if [ ! -f "$file" ]; then
  wget -q --output-document "$file" https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php
fi

# adminer script

file='adminer.php'

if [ ! -f "$file" ]; then
  wget -q --output-document "$file" http://www.adminer.org/latest.php
  wget -q https://raw.githubusercontent.com/vrana/adminer/master/designs/pepa-linha/adminer.css
fi

# git

apt-get install -q -y git

# composer

php -r "readfile('https://getcomposer.org/installer');" | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# modman

bash < <(wget -q --no-check-certificate -O - https://raw.github.com/colinmollenhour/modman/master/modman-installer)
mv /root/bin/modman /usr/local/bin/modman
chmod +x /usr/local/bin/modman

if [ ! -d .modman ]; then
  modman init
fi

# modgit

wget -q -O modgit https://raw.github.com/jreinke/modgit/master/modgit
mv modgit /usr/local/bin/modgit
chmod +x /usr/local/bin/modgit

if [ ! -d .modgit ]; then
  modgit init
fi

# magento apache config

SITE_CONF=$(cat <<EOF
<Directory /var/www/html>
  AllowOverride All
  Options -Indexes -MultiViews +FollowSymLinks
  AddDefaultCharset utf-8
  SetEnv MAGE_IS_DEVELOPER_MODE "true"
  php_flag display_errors On
</Directory>
EOF
)

echo "$SITE_CONF" > /etc/apache2/sites-available/magento.conf

a2ensite magento

service apache2 reload

# magento mysql user and database

mysql -u root -p"$MYSQL_ROOT_USER_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_MAGENTO_DB_NAME DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci'"
mysql -u root -p"$MYSQL_ROOT_USER_PASSWORD" -e "CREATE USER '$MYSQL_MAGENTO_USER_NAME'@'localhost' IDENTIFIED BY '$MYSQL_MAGENTO_USER_PASSWORD'"
mysql -u root -p"$MYSQL_ROOT_USER_PASSWORD" -e "GRANT ALL ON $MYSQL_MAGENTO_DB_NAME.* TO '$MYSQL_MAGENTO_USER_NAME'@'localhost'"
mysql -u root -p"$MYSQL_ROOT_USER_PASSWORD" -e "FLUSH PRIVILEGES"

# magento files

MAGENTO_VERSION='1.9.1.1'
MAGENTO_SAMPLE_DATA_VERSION='1.9.1.0'

if [ ! -f app/etc/config.xml ]; then

  # magento

  dir='magento'

  if [ -d "$dir" ]; then
    rm -rf "$dir"
  fi

  file="magento-$MAGENTO_VERSION.tar.gz"
  
  if [ ! -f "$file" ]; then
    if [ -f /vagrant/vagrant-bootstrap-files/"$file" ]; then
      cp /vagrant/vagrant-bootstrap-files/"$file" .
    else
      wget "http://www.magentocommerce.com/downloads/assets/$MAGENTO_VERSION/$file"
    fi
  fi

  tar -zxvf "$file"

  mv magento/* magento/.htaccess* .

  rmdir "$dir"
  
  # magento patches
  
  file="PATCH_SUPEE-5994_CE_1.6.0.0_v1-2015-05-15-04-34-46.sh"

  if [ -f /vagrant/vagrant-bootstrap-files/"$file" ]; then
    cp /vagrant/vagrant-bootstrap-files/"$file" .
    sh "$file"
  fi

  file="PATCH_SUPEE-6237_EE_1.14.2.0_v1-2015-06-18-05-24-23.sh"

  if [ -f /vagrant/vagrant-bootstrap-files/"$file" ]; then
    cp /vagrant/vagrant-bootstrap-files/"$file" .
    sh "$file"
  fi
  
  # magento channels

  ./mage mage-setup

  # magento sample data

  if [ "$MAGENTO_INSTALL_SAMPLE_DATA" = true ]; then
  
    # files
  
    dir="magento-sample-data-$MAGENTO_SAMPLE_DATA_VERSION"

    if [ -d "$dir" ]; then
      rm -rf "$dir"
    fi

    file="magento-sample-data-$MAGENTO_SAMPLE_DATA_VERSION.tar.gz"

    if [ ! -f "$file" ]; then
      if [ -f /vagrant/vagrant-bootstrap-files/"$file" ]; then
        cp /vagrant/vagrant-bootstrap-files/"$file" .
      else
        wget "http://www.magentocommerce.com/downloads/assets/$MAGENTO_SAMPLE_DATA_VERSION/$file"
      fi
    fi

    tar -zxvf "$file"
  
    cp -R "$dir"/media/* ./media/
    cp -R "$dir"/skin/* ./skin/
	
	# database
  
    mysql -u "$MYSQL_MAGENTO_USER_NAME" -p"$MYSQL_MAGENTO_USER_PASSWORD" "$MYSQL_MAGENTO_DB_NAME" < "$dir/magento_sample_data_for_$MAGENTO_SAMPLE_DATA_VERSION.sql"
	
    rm -rf "$dir"
	
	# language packs
	
    ./mage install http://connect20.magentocommerce.com/community/ Locale_Mage_community_fr_FR
    ./mage install http://connect20.magentocommerce.com/community/ Locale_Mage_community_de_DE
  fi
fi

# magento permissions

chmod -R o+w media var
chmod o+w var var/.htaccess app/etc

# magento install

if [ ! -f app/etc/local.xml ]; then
  /usr/bin/php -f install.php -- \
  --license_agreement_accepted 'yes' \
  --locale "$MAGENTO_LOCALE" --timezone "$TIME_ZONE" --default_currency "$MAGENTO_CURRENCY" \
  --db_model 'mysql4' --db_host 'localhost' --db_name "$MYSQL_MAGENTO_DB_NAME" --db_user "$MYSQL_MAGENTO_USER_NAME" --db_pass "$MYSQL_MAGENTO_USER_PASSWORD" \
  --url 'http://127.0.0.1:8080/' --admin_frontname "$MAGENTO_ADMIN_PATH" --enable_charts 'yes' --skip_url_validation 'yes' --use_rewrites 'yes' --use_secure 'no' --secure_base_url 'http://127.0.0.1:8080/' --use_secure_admin 'no' \
  --session_save 'files' \
  --admin_firstname 'Store' --admin_lastname 'Owner' --admin_email 'admin@example.com' \
  --admin_username "$MAGENTO_ADMIN_USER_NAME" --admin_password "$MAGENTO_ADMIN_USER_PASSWORD"
fi

# magento re-index

/usr/bin/php -f shell/indexer.php reindexall

# netz98 magerun CLI tools

wget -q --no-check-certificate https://raw.github.com/netz98/n98-magerun/master/n98-magerun.phar
mv n98-magerun.phar /usr/local/bin/
chmod +x /usr/local/bin/n98-magerun.phar
