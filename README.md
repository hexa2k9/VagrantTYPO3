Vagrant Config for TYPO3 Flow Development
=========================================

Disclaimer: 
This is a fork of git://github.com/mrimann/VagrantTYPO3Flow.git heavily inspired by his works (including the .md file) and just some minor changes to PHP Version and NginX Version shiped with it.

I played around with https://puphpet.com for a little while, but reached the point where it would have required to much work to proceed further, although I reached my main goal, a prove of concept pretty fast.

Those of you who know me personaly know that I like to keep my dev environments slim, and bleeding edge. That's why I forked Marios repo do get a shipable product. 
The Box is setup for TYPO3.Flow and TYPO3.Neos as well as TYPO3.CMS development with all necessary components configured to get you up and running in a bliz.

The usual approach (ok, seen more-often than this) is to have one Vagrant based system per project. While that makes perfectly sense in many situations, I needed something more convinient: I'm working on a lot of projects, often sandboxing proof of concepts, my Vagrant setup suffices the following requirements:

- I need to be able to work offline
- I want a minimum overhead for creating a new "site" or virtual host
- I prefer the GUI Git client ([Tower](http://www.git-tower.com/)) over the command line - so the project files shall remain locally on the host system
- I want a documented and recoverable setup of the VM

For that I thought of a solution based on Apaches *vhost_alias" module, which allows me to call whatever domain name I want - and it will be dynamically mapped locally. E.g. for a request for "example.com", without having to declare that in a vHost directive for each new project. Just let the DNS or hosts file point to the IP of the Vagrant box and you're ready to go. The subdirectory "vHost" of this repository is mounted as /var/www in the guest OS.

Installation:
-------------

Install [Vagrant](http://vagrantup.com/) with the installer that fits your hosts operating system.

Download and Install [VirtualBox](http://www.virtualbox.org/) or if you prefer [VMWare](https://www.vmware.com/products/workstation/) / [VMWare Fusion](https://www.vmware.com/products/fusion-professional/)
In the later case you will need to buy and install the [Vagrant Plugin](http://www.vagrantup.com/vmware) for VmWare.

Clone this repository

	git clone git://github.com/swiftlizard/VagrantTYPO3.git

Change to the cloned repository

	cd VagrantTYPO3

Install Plugin vbguest which keeps your boxes in sync with you virtualbox version:

	vagrant plugin install vagrant-vbguest

Boot up the virtual box:

	vagrant up

If you are using a Mac you have to enter the root passwort of you Mac while the boot up. This is caused by the nfs mounting that requires root access.

The box gets one static IP addresses **192.168.50.50** which is only accessible from your local computer.

Now add any project you're working on (e.g. "example.com") to your hosts file and let it point to 192.168.50.50 and create a directory with the domain name within the sub-directory "vHosts". As soon as you call that domain from your browser, you should see it working.

The IP addresse is for  Nginx - this means you can direct the request the webserver via your hosts file entry:

* Nginx listens on 192.168.50.50 on port 80

For name resolution from within the guest system lookups to *.dev, *.prod and *.lo it will always result in the IP of Nginx (192.168.50.50).

If you're running a [TYPO3 Flow](http://flow.typo3.org/) based web-application where the document-root must point to a sub-directory (e.g. /Web/), you can solve this with a little symlink as shown in the following (pseudo) directory listing:

	Vagrant-Directory
	|-> vHosts
		|-> example.com -> example-Distribution/Web/

To log in via SSH, just execute the following command from within the current directory:

	vagrant ssh

If you fiddle around/extend/change/improve with the Puppet manifests contained in here, you can simple re-run the puppet apply command from outside of the VM with the following command (instead of rebooting the VM):

	vagrant provision


What it contains:
-----------------

- MySQL server (user: *root*, password *vagrant*)
- PHP 5.5.x
- Nginx 1.4.x with mass host config
- Memchached
- Redis Server
- nano-Editor
- git and tig
- Composer (installed + kept up to date)
- XHProf including XHProf.io Web Gui pre installed running at xhprof.io.lo on the guest system
- [Xdebug](http://xdebug.org/) 


TODO:
-----
During the next months I will try to get a redundant 3 Layer Setup to be created (2x HA-Proxy, 2x Webserver, 2x DB Server Master->Slave, 1xNFS) based on this setup.
Lets see how far I will get ... Help is more than welcome.

## License

Licensed under the permissive [MIT license](http://opensource.org/licenses/MIT) - have fun with it!

### Can I use it in commercial projects?

Yes, please! And if you save some of your precious time with it, I'd be very happy if you give Mario something back - be it a warm "Thank you" by mail, spending him a drink at a conference, [send him a post card or some other surprise](http://www.rimann.org/support/) :-)
