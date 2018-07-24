#!/usr/bin/env bash

# author Aurélien Millet
# link https://github.com/aurmil/magento-vagrant-provisioner
# license https://github.com/aurmil/magento-vagrant-provisioner/blob/master/LICENSE.md

# configuration

TIME_ZONE=$1
MAGENTO_VERSION=$2
MAGENTO_INSTALL_SAMPLE_DATA=$3
MAGENTO_SAMPLE_DATA_VERSION=$4
MYSQL_MAGENTO_DB_NAME='magento1'
MYSQL_MAGENTO_USER_NAME='magento1'
MYSQL_MAGENTO_USER_PASSWORD='magento1'
MAGENTO_LOCALE=$5
MAGENTO_CURRENCY=$6
MAGENTO_URL='http://127.0.0.1:8080/'
MAGENTO_ADMIN_PATH='admin'
MAGENTO_ADMIN_USER_NAME='admin'
MAGENTO_ADMIN_USER_PASSWORD='magento1'

# disable queries for user manual interactions

export DEBIAN_FRONTEND=noninteractive

# update time zone

echo "$TIME_ZONE" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# update packages

apt-get update -q

# install Vim and Git

apt-get install -q -y vim git

# install Apache, PHP and MySQL

apt-get install -q -y apache2 apache2.2-common
apt-get install -q -y php5 libapache2-mod-php5
apt-get install -q -y php5-curl php5-gd php5-mcrypt php5-mysqlnd php-soap php5-xdebug
apt-get install -q -y mysql-server-5.5

a2enmod rewrite headers
service apache2 restart

# set Vagrant folder as Apache root folder and go to it

dir='/vagrant/www'

if [ ! -d "$dir" ]; then
  mkdir "$dir"
fi

if [ ! -L /var/www/html ]; then
  rm -rf /var/www/html
  ln -fs "$dir" /var/www/html
fi

cd "$dir"

# Magento vhost

file='/etc/apache2/sites-available/magento1.conf'

if [ ! -f "$file" ]; then
  SITE_CONF=$(cat <<EOF
<Directory /var/www/html>
  AllowOverride All
  Options -Indexes -MultiViews +FollowSymLinks
  AddDefaultCharset utf-8
  SetEnv MAGE_IS_DEVELOPER_MODE "true"
  php_flag display_errors On
  EnableSendfile Off
</Directory>
EOF
)
  echo "$SITE_CONF" > "$file"
fi

a2ensite magento1
service apache2 reload

# Magento database and user

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $MYSQL_MAGENTO_DB_NAME DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci'"
mysql -u root -e "GRANT ALL ON $MYSQL_MAGENTO_DB_NAME.* TO '$MYSQL_MAGENTO_USER_NAME'@'localhost' IDENTIFIED BY '$MYSQL_MAGENTO_USER_PASSWORD'"
mysql -u root -e "FLUSH PRIVILEGES"

# Magento files

if [ ! -f app/etc/config.xml ]; then
  dir="magento-mirror-$MAGENTO_VERSION"
  file="magento-$MAGENTO_VERSION.tar.gz"

  # if folder already exists, remove it
  if [ -d "$dir" ]; then
    rm -rf "$dir"
  fi

  # if file does not exist, download it
  if [ ! -f "$file" ]; then
    wget -nv -O "$file" "https://github.com/OpenMage/magento-mirror/archive/$MAGENTO_VERSION.tar.gz"
  fi

  # if file exists, extract content
  if [ -f "$file" ]; then
    tar -zxf "$file"
    mv "$dir"/* "$dir"/.htaccess* .
    rm -rf "$dir"
  fi

  # init channels
  ./mage mage-setup

  # install sample data if needed
  if [ "$MAGENTO_INSTALL_SAMPLE_DATA" = true ]; then
    dir="magento-sample-data-$MAGENTO_SAMPLE_DATA_VERSION"
    file="$dir.tar.gz"

    # if folder already exists, remove it
    if [ -d "$dir" ]; then
      rm -rf "$dir"
    fi

    # if file does not exist, download it
    if [ ! -f "$file" ]; then
      wget -nv "https://raw.githubusercontent.com/aurmil/magento-compressed-sample-data/master/$MAGENTO_SAMPLE_DATA_VERSION/$file"
    fi

    # if file exists, extract content and install sample data
    if [ -f "$file" ]; then
      tar -zxf "$file"
      cp -R "$dir"/media/* ./media/
      cp -R "$dir"/skin/* ./skin/
      mysql -u "$MYSQL_MAGENTO_USER_NAME" -p"$MYSQL_MAGENTO_USER_PASSWORD" "$MYSQL_MAGENTO_DB_NAME" < "$dir/magento_sample_data_for_$MAGENTO_SAMPLE_DATA_VERSION.sql"
      rm -rf "$dir"
    fi

    # install language packs
    ./mage install http://connect20.magentocommerce.com/community/ Locale_Mage_community_fr_FR
    ./mage install http://connect20.magentocommerce.com/community/ Locale_Mage_community_de_DE
  fi
fi

chmod -R o+w media var
chmod o+w var var/.htaccess app/etc

# Magento install

if [ ! -f app/etc/local.xml ]; then
  /usr/bin/php -f install.php -- \
  --license_agreement_accepted 'yes' \
  --locale "$MAGENTO_LOCALE" --timezone "$TIME_ZONE" --default_currency "$MAGENTO_CURRENCY" \
  --db_model 'mysql4' --db_host 'localhost' --db_name "$MYSQL_MAGENTO_DB_NAME" --db_user "$MYSQL_MAGENTO_USER_NAME" --db_pass "$MYSQL_MAGENTO_USER_PASSWORD" \
  --url "$MAGENTO_URL" --admin_frontname "$MAGENTO_ADMIN_PATH" --enable_charts 'yes' --skip_url_validation 'yes' --use_rewrites 'yes' --use_secure 'no' --secure_base_url "$MAGENTO_URL" --use_secure_admin 'no' \
  --session_save 'files' \
  --admin_firstname 'Store' --admin_lastname 'Owner' --admin_email 'admin@example.com' \
  --admin_username "$MAGENTO_ADMIN_USER_NAME" --admin_password "$MAGENTO_ADMIN_USER_PASSWORD"
fi

/usr/bin/php -f shell/indexer.php reindexall

# Composer

EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
  >&2 echo 'ERROR: Invalid installer signature (Composer)'
  rm composer-setup.php
else
  php composer-setup.php --quiet
  rm composer-setup.php

  mv composer.phar /usr/local/bin/composer
  chmod +x /usr/local/bin/composer

  sudo -H -u vagrant bash -c 'composer global require hirak/prestissimo'
fi

# phpinfo script

file='phpinfo.php'

if [ ! -f "$file" ]; then
  echo '<?php phpinfo();' > "$file"
fi

# OPcache gui script

file='opcache.php'

if [ ! -f "$file" ]; then
  wget -nv -O "$file" https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php
fi

# Adminer script

file='adminer.php'

if [ ! -f "$file" ]; then
  wget -nv -O "$file" http://www.adminer.org/latest.php
  wget -nv https://raw.githubusercontent.com/vrana/adminer/master/designs/pepa-linha/adminer.css
fi

# modman

bash < <(wget -nv --no-check-certificate -O - https://raw.github.com/colinmollenhour/modman/master/modman-installer)
mv /root/bin/modman /usr/local/bin/modman
chmod +x /usr/local/bin/modman

if [ ! -d .modman ]; then
  modman init
fi

# netz98 magerun CLI tools

wget -nv https://files.magerun.net/n98-magerun.phar
chmod +x ./n98-magerun.phar
mv ./n98-magerun.phar /usr/local/bin/

# hide admin notifications

n98-magerun.phar admin:notifications

# enable form key validation on checkout

n98-magerun.phar config:set admin/security/validate_formkey_checkout 1
n98-magerun.phar cache:clean config
