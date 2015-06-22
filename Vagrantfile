# -*- mode: ruby -*-
# vi: set ft=ruby :
 
Vagrant.configure("2") do |config|

  config.vm.box = "debian/jessie64"
  
  config.vm.network "forwarded_port", guest: 80, host: 8080
  
  config.vm.provider "virtualbox" do |vb|
    vb.name = "vagrant_magento"
	vb.memory = 1024
	vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
  end
  
  config.vm.provision "shell", path: "vagrant-bootstrap-files/bootstrap.sh"
  
  config.vm.synced_folder ".", "/vagrant", owner: "www-data", group: "www-data"

end
