# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_plugin "vagrant-vbguest"

Vagrant.configure("2") do |config|
	config.vm.box = "precise64"
	config.vm.box_url = "http://files.vagrantup.com/precise64.box"

	config.vm.network :private_network, ip: "192.168.50.50"

	config.vm.synced_folder "vHosts/", "/var/www/", type: "nfs", owner: "www-data", group: "www-data"

	# configure the VM via Puppet
	config.vm.provision :puppet

	config.vm.provider "vmware_fusion" do |vmware_fusion, override|
		override.vm.box     = "precise64_vmware_fusion"
		override.vm.box_url = "http://files.vagrantup.com/precise64_vmware_fusion.box"

		vmware_fusion.vmx["memsize"] = "2048"
		vmware_fusion.vmx["numvcpus"] = "2"
	end

	config.vm.provider "vmware_workstation" do |vmware_workstation, override|
		override.vm.box     = "precise64_vmware"
		override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"
		override.vm.synced_folder "vHosts/", "/var/www/", owner: "www-data", group: "www-data"

		vmware_workstation.vmx["memsize"] = "2048"
		vmware_workstation.vmx["numvcpus"] = "2"
	end

	config.vm.provider "virtualbox" do |vb, override|
		vb.customize ["modifyvm", :id, "--memory", "2048"]
		vb.customize ["modifyvm", :id, "--cpus", "2"]   
	end  
end
