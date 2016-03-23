# Magento provisioner for Vagrant

Development environment for Magento, automatically configured and ready to use.

## What's included?

LAMP

* Debian 8 (jessie), 64-bit
* Apache 2.4 (with mod_rewrite)
* MySQL 5.5
* PHP 5.6

Magento

* Magento CE 1.9.2.2 (from [OpenMage GitHub repo](https://github.com/OpenMage/magento-mirror) as Magento official website requires user to be logged in to download the archive)
* Magento Sample Data 1.9.1.0 (optional ; from [Vinai compressed versions GitHub repo](https://github.com/Vinai/compressed-magento-sample-data) as Magento official website requires user to be logged in to download the archive ; with [French](http://www.magentocommerce.com/magento-connect/french-france-language-pack-for-magento-traduction-francaise.html) and [German](http://www.magentocommerce.com/magento-connect/locale-mage-community-de-de.html) language packs)
* [modman](https://github.com/colinmollenhour/modman)
* [modgit](https://github.com/jreinke/modgit)
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

__Note on sample data:__

If you want to install the sample data, you can speed up the environment installation (first `vagrant up`) by downloading on your own the 430 MB archive in .tar.gz format from [Magento website](https://www.magentocommerce.com/download) then just put `magento-sample-data-1.x.y.z.tar.gz` file in the `vagrant-bootstrap-files` folder.

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

Some variables are located in a dedicated file `vagrant-bootstrap-files/bootstrap.cfg` so they can be easily changed:

* System and Magento time zone (default = Europe/Paris)
* Install Magento sample data or not (default = yes)
* Magento locale (default = English)
* Magento currency (default = Euro)
