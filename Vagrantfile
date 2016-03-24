# -*- mode: ruby -*-
# vi: set ft=ruby :

# author Aurélien Millet
# link https://github.com/aurmil/magento-vagrant-provisioner
# license https://github.com/aurmil/magento-vagrant-provisioner/blob/master/LICENSE.md

# configuration
time_zone = "Europe/Paris"
magento_install_sample_data = "true"
magento_locale = "en_US"
magento_currency = "EUR"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/jessie64"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.ssh.forward_agent = true
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox",
    owner: "www-data", group: "www-data"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "vagrant_magento1"
    vb.memory = 1024
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "shell" do |s|
    s.path = "bootstrap.sh"
    s.args = [time_zone, magento_install_sample_data, magento_locale, magento_currency]
  end
end
