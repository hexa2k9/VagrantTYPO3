# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_plugin "vagrant-vbguest"

Vagrant.configure("2") do |config|
	config.vm.box = "precise64"
	config.vm.box_url = "http://files.vagrantup.com/precise64.box"

	config.vm.network :private_network, ip: "192.150.50.50"
 
	config.vm.synced_folder "vHosts/", "/var/www/", type: "nfs"

	# configure the VM via Puppet
	config.vm.provision :puppet

	config.vm.provider "vmware_fusion" do |vmware, override|
		override.vm.box     = "precise64_vmware_fusion"
        override.vm.box_url = "http://files.vagrantup.com/precise64_vmware_fusion.box"

 		vmware.vmx["memsize"] = "2048"
  		vmware.vmx["numvcpus"] = "2"
	end

	config.vm.provider "vmware_workstation" do |vmware, override|
		override.vm.box     = "precise64_vmware"
        override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"

 		vmware.vmx["memsize"] = "2048"
  		vmware.vmx["numvcpus"] = "2"
	end

	config.vm.provider "virtualbox" do |vb, override|
    	vb.customize ["modifyvm", :id, "--memory", "2048"]
    	vb.customize ["modifyvm", :id, "--cpus", "2"]   
 	 end  
end