# Magento provisioner for Vagrant

Development environment for Magento, automatically configured and ready to use.

## What's included?

LAMP

* Debian 8 (Jessie), 64-bit
* Apache 2.4 (with mod_rewrite)
* MySQL 5.5
* PHP 5.6

Magento

* Magento Open Source 1.9.4.1 (from [OpenMage GitHub repo](https://github.com/OpenMage/magento-mirror) as Magento official website requires user to be logged in to download the archive)
* Magento Sample Data 1.9.2.4 (optional ; from [my compressed sample data GitHub repo](https://github.com/aurmil/magento-compressed-sample-data) as Magento official website requires user to be logged in to download the archive ; with [French](http://www.magentocommerce.com/magento-connect/french-france-language-pack-for-magento-traduction-francaise.html) and [German](http://www.magentocommerce.com/magento-connect/locale-mage-community-de-de.html) language packs)
* [modman](https://github.com/colinmollenhour/modman)
* [netz98 magerun CLI tools](https://github.com/netz98/n98-magerun)

Tools

* Vim
* Git
* [Composer](https://getcomposer.org/)
* phpinfo script
* [OpCache GUI script](https://github.com/amnuts/opcache-gui)
* [Adminer](http://www.adminer.org/)

## Requirements

* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)
* VirtualBox Guest Additions on the guest system => [vagrant-vbguest Vagrant plugin](https://github.com/dotless-de/vagrant-vbguest)
* RAM: this virtual machine is configured to use 1 GB

## Installation

* [Download](https://github.com/aurmil/magento-vagrant-provisioner/archive/master.zip) or clone this repository into your project's folder
* Run `vagrant up` in this folder

## Usage

See the [Vagrant official docs for `vagrant up / ssh / halt / destroy` commands](http://docs.vagrantup.com/v2/cli/index.html) usage.

Within a web browser, you can access:
* Magento front office `http://127.0.0.1:8080/`
* Magento back office `http://127.0.0.1:8080/admin/`, credentials are: `admin` / `magento1`
* Adminer `http://127.0.0.1:8080/adminer.php`, credentials are: `magento1` / `magento1` or `root` / nothing
* phpinfo script `http://127.0.0.1:8080/phpinfo.php`
* OpCache GUI script `http://127.0.0.1:8080/opcache.php`

Application files are located in `your-project-folder/www`, you can manage them directly from your host machine.

## Customizable configuration

Some variables are located at the top of Vagrantfile so they can be easily changed:

* System and Magento time zone (default = Europe/Paris)
* Install Magento sample data or not (default = yes)
* Magento locale (default = English)
* Magento currency (default = Euro)

## License

The MIT License (MIT). Please see [License File](https://github.com/aurmil/magento-vagrant-provisioner/blob/master/LICENSE.md) for more information.
