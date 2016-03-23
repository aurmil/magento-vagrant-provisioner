#!/usr/bin/env bash

# configuration

file='/vagrant/vagrant-bootstrap-files/bootstrap.cfg'
file_secured='/tmp/bootstrap.cfg'

if egrep -q -v '^#|^[^ ]*=[^;]*' "$file"; then
  egrep '^#|^[^ ]*=[^;&]*'  "$file" > "$file_secured"
  file="$file_secured"
fi

. "$file"

MAGENTO_VERSION='1.9.2.4'
MAGENTO_SAMPLE_DATA_VERSION='1.9.1.0' # only version supported!

MYSQL_MAGENTO_DB_NAME='magento1'
MYSQL_MAGENTO_USER_NAME='magento1'
MYSQL_MAGENTO_USER_PASSWORD='magento1'

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

# vim
apt-get install -q -y vim

# git
apt-get install -q -y git

# apache
apt-get install -q -y apache2 apache2.2-common
a2enmod rewrite headers
service apache2 restart

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

# php
apt-get install -q -y php5 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysqlnd php-soap php5-xdebug
service apache2 restart

# composer
php -r "readfile('https://getcomposer.org/installer');" | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# phpinfo script
file='phpinfo.php'
if [ ! -f "$file" ]; then
  echo '<?php phpinfo();' > "$file"
fi

# opcache gui script
file='opcache.php'
if [ ! -f "$file" ]; then
  wget -nv -O "$file" https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php
fi

# mysql
apt-get install -q -y mysql-server-5.5

# adminer script
file='adminer.php'
if [ ! -f "$file" ]; then
  wget -nv -O "$file" http://www.adminer.org/latest.php
  wget -nv https://raw.githubusercontent.com/vrana/adminer/master/designs/pepa-linha/adminer.css
fi

# magento mysql user and database
mysql -u root -e "CREATE DATABASE IF NOT EXISTS $MYSQL_MAGENTO_DB_NAME DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci'"
mysql -u root -e "CREATE USER '$MYSQL_MAGENTO_USER_NAME'@'localhost' IDENTIFIED BY '$MYSQL_MAGENTO_USER_PASSWORD'"
mysql -u root -e "GRANT ALL ON $MYSQL_MAGENTO_DB_NAME.* TO '$MYSQL_MAGENTO_USER_NAME'@'localhost'"
mysql -u root -e "FLUSH PRIVILEGES"

# magento vhost
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
echo "$SITE_CONF" > /etc/apache2/sites-available/magento1.conf
a2ensite magento1
service apache2 reload

# magento files
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

    # if file does not exist, search it elsewhere or download it
    if [ ! -f "$file" ]; then
      if [ -f /vagrant/vagrant-bootstrap-files/"$file" ]; then
        cp /vagrant/vagrant-bootstrap-files/"$file" .
      else
        wget -nv -O "$file" "https://raw.githubusercontent.com/Vinai/compressed-magento-sample-data/$MAGENTO_SAMPLE_DATA_VERSION/compressed-$dir.tgz"
      fi
    fi

    # if file exists, extract content and install sample data
    if [ -f "$file" ]; then
      tar -zxf "$file"
      mv "$dir"/media/* ./media/
      mv "$dir"/skin/* ./skin/
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

# magento install
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

# magento re-index
/usr/bin/php -f shell/indexer.php reindexall

# modman
bash < <(wget -nv --no-check-certificate -O - https://raw.github.com/colinmollenhour/modman/master/modman-installer)
mv /root/bin/modman /usr/local/bin/modman
chmod +x /usr/local/bin/modman
if [ ! -d .modman ]; then
  modman init
fi

# modgit
wget -nv -O modgit https://raw.github.com/jreinke/modgit/master/modgit
mv modgit /usr/local/bin/modgit
chmod +x /usr/local/bin/modgit
if [ ! -d .modgit ]; then
  modgit init
fi

# netz98 magerun CLI tools
wget -nv --no-check-certificate https://raw.github.com/netz98/n98-magerun/master/n98-magerun.phar
mv n98-magerun.phar /usr/local/bin/
chmod +x /usr/local/bin/n98-magerun.phar
