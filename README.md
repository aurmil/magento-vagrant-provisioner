# Magento provisioner for Vagrant

Development environment for Magento, automatically configured and ready to use.

## What's included?

LAMP

* Debian 8 (jessie), 64-bit
* Apache 2.4 (with mod_rewrite)
* MySQL 5.5
* PHP 5.6

Magento

* Magento CE 1.9.1.1 (with patches SUPEE-5994 and SUPEE-6237)
* Magento Sample Data 1.9.1.0 (optional ; with [French](http://www.magentocommerce.com/magento-connect/french-france-language-pack-for-magento-traduction-francaise.html) and [German](http://www.magentocommerce.com/magento-connect/locale-mage-community-de-de.html) language packs)
* [netz98 magerun CLI tools](https://github.com/netz98/n98-magerun)
* [modman](https://github.com/colinmollenhour/modman)
* [modgit](https://github.com/jreinke/modgit)

Tools

* Vim
* Git
* [Composer](https://getcomposer.org/)
* phpMyAdmin
* phpinfo script
* [OpCache GUI script](https://github.com/amnuts/opcache-gui)

## Requirements

* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)
* RAM: this virtual machine is configured to use 1 GB

## Installation

* [Download](https://github.com/aurmil/magento-vagrant-provisioner/archive/master.zip) or clone this repository into your project's folder
* Run `vagrant up` in this folder

__Note:__

To speed up the environment installation (first `vagrant up`), you can download Magento and sample data (if you want to install it) in .tar.gz format [from the official site](https://www.magentocommerce.com/download) and put `magento-1.9.1.1.tar.gz` and `magento-sample-data-1.9.1.0.tar.gz` files in the `vagrant-bootstrap-files` folder. Doing so will avoid downloading them from within the virtual machine.

## Usage

See the [Vagrant official docs for `vagrant up / ssh / halt / destroy` commands](http://docs.vagrantup.com/v2/cli/index.html) usage.

Within a web browser, you can access:
* Magento front office `http://127.0.0.1:8080/`
* Magento back office `http://127.0.0.1:8080/admin/`, credentials are: `admin` / `magento1`  (unless you customized these datas)
* phpMyAdmin `http://127.0.0.1:8080/phpmyadmin/`
* phpinfo script `http://127.0.0.1:8080/info.php`
* OpCache GUI script `http://127.0.0.1:8080/opcache.php`

Application files are located in `your-project-folder/www`, you can manage them directly from your host machine.

## Customizable configuration

Some variables are located in a dedicated file `vagrant-bootstrap-files/bootstrap.cfg` so they can be easily changed:

* MySQL root user password
* MySQL phpMyAdmin user password
* MySQL Magento database name, user name and password
* Install Magento sample data or not (default = yes)
* System and Magento time zone (default = Europe/Paris)
* Magento locale (default = English)
* Magento currency (default = Euro)
* Magento admin path (default = admin), login (default = admin) and password (default = magento1)
