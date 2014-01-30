# ---------------------------------------------------
# Basic system stuff
# ---------------------------------------------------

# Ensure system is up to date
exec { 'aptitude upgrade':
	command => '/usr/bin/sudo aptitude -y upgrade',
}

package {'apparmor':
	ensure => absent,
	require => Exec['aptitude upgrade'],
}
package { 'unzip':
	ensure => present,
	require => Exec['aptitude upgrade'],
}

package { 'curl':
	ensure => present,
	require => Exec['aptitude upgrade'],
}

package { 'nano':
	ensure => present,
	require => Exec['aptitude upgrade'],
}

package { 'git':
	ensure => present,
	require => Exec['aptitude upgrade'],
}

package { 'tig':
	ensure => present,
	require => Exec['aptitude upgrade'],
}

exec { "Import repo signing key to apt keys":
	path   => "/usr/bin:/usr/sbin:/bin",
	command     => "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C",
	unless      => "apt-key list | grep E5267A6C",
	require => Exec['aptitude upgrade'],
}

exec { "Import repo signing key to apt keys 2":
	path   => "/usr/bin:/usr/sbin:/bin",
	command     => "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ABF5BD827BD9BF62",
	unless      => "apt-key list | grep ABF5BD827BD9BF62",
	require => Exec['aptitude upgrade'],
}

exec { 'apt-get update':
	command => '/usr/bin/sudo apt-get update',
	require => Exec['aptitude upgrade'],
}

package { "python-software-properties":
	ensure => present,
	require => Exec['apt-get update'],
}


exec { 'adding new nginx':
	command => '/usr/bin/sudo add-apt-repository -y "deb http://nginx.org/packages/ubuntu/ precise nginx"',
	require => Package['python-software-properties']
}

exec { 'adding ppa:ondrej/php5':
	command => '/usr/bin/sudo add-apt-repository -y ppa:ondrej/php5',
	require => Package['python-software-properties']
}

exec { 'apt-get update final':
	command => '/usr/bin/sudo apt-get update',
	require => [
		Package['python-software-properties'],
		Exec['adding new nginx'],
		Exec['adding ppa:ondrej/php5'],
	]
}


# ---------------------------------------------------
# Install MySQL
# ---------------------------------------------------

package { "mysql-server":
	ensure => present,
	require => Exec['apt-get update final'],
}

service { 'mysql':
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	enable => true,
	require => Package["mysql-server"],
}

exec { 'mysql-root-password':
	command => '/usr/bin/mysqladmin -u root password vagrant',
	onlyif => '/usr/bin/mysql -u root mysql -e "show databases;"',
	require => Package['mysql-server'],
}

exec { 'mysql-root-create-xhprof-db':
	command => '/usr/bin/mysql -uroot -pvagrant -e "create database if not exists xhprof CHARACTER SET utf8 COLLATE utf8_general_ci;" ',
	require => Exec['mysql-root-password'],
}

exec { 'mysql-root-import-xhprof-db':
	command => '/usr/bin/mysql -uroot -pvagrant xhprof < /var/www/xhprof.io/setup/database.sql',
	require => Exec['mysql-root-create-xhprof-db'],
}

# ---------------------------------------------------
# Install Cache Servers
# ---------------------------------------------------
package { 'memcached':
	ensure => installed,
	require => Exec['apt-get update final'],
}

package { 'redis-server':
	ensure => installed,
	require => Exec['apt-get update final'],
}


# ---------------------------------------------------
# Install PHP 5.5.x with FPM
# ---------------------------------------------------

package { 'php5-fpm':
	ensure => installed,
	require => Exec['apt-get update final'],
}

package { 'php5-mysqlnd':
	ensure => installed,
	require => Exec['apt-get update final'],
	notify => Service['php5-fpm'],
}

package { 'php5-mcrypt':
	ensure => installed,
	require => Exec['apt-get update final'],
	notify => Service['php5-fpm'],
}
package { 'php5-curl':
	ensure => installed,
	require => Exec['apt-get update final'],
	notify => Service['php5-fpm'],
}
package { 'php5-gd':
	ensure => installed,
	require => Exec['apt-get update final'],
	notify => Service['php5-fpm'],
}
package { 'php5-cli':
	ensure => installed,
	require => Exec['apt-get update final'],
}
package { 'php5-memcache':
	ensure => installed,
	require => Exec['apt-get update final'],
}
package { 'php5-redis':
	ensure => installed,
	require => Exec['apt-get update final'],
}
package { 'php5-dev':
	ensure => installed,
	require => Exec['apt-get update final'],
}

package { 'php5-xdebug':
	ensure => installed,
	require => Exec['apt-get update final'],
}

exec { 'install_xhprof':
	command => '/usr/bin/pecl install -f xhprof',
	require => Package['php5-dev'],
	notify => Service['php5-fpm'],
  }

package { ['graphviz']:
    ensure  => installed,
    notify  => Service['php5-fpm'],
  }

service { 'php5-fpm':
	ensure => running,
	require => Package['php5-fpm'],
	hasrestart => true,
	hasstatus => true,
}

file { '/etc/php5/fpm/pool.d/www.conf':
	ensure => present,
	source => "/vagrant/manifests/files/php/www.conf",
	require => [
		Package['php5-fpm']
	],
	notify => [
		Service['php5-fpm'],
	],
}


file { '/etc/php5/fpm/conf.d/90-vagrant.ini':
	ensure => present,
	source => "/vagrant/manifests/files/php/90-vagrant.ini",
	require => [
		Package['php5-fpm'],
	],
	notify => [
		Service['php5-fpm'],
	],
}

file { '/etc/php5/cli/conf.d/90-vagrant.ini':
	ensure => present,
	source => "/vagrant/manifests/files/php/90-vagrant.ini",
	require => [
		Package['php5-cli'],
	],
}


# ---------------------------------------------------
# Install Composer
# ---------------------------------------------------
exec { 'install-composer':
	command => 'curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer',
	path => "/usr/local/bin/:/usr/bin/:/bin/",
	timeout => 0,
	creates => "/usr/local/bin/composer",
	require => [
		Package['curl'],
		Package['php5-cli'],
	],
}

exec { 'selfupdate-composer':
	command => 'sudo composer self-update',
	path => "/usr/local/bin/:/usr/bin/",
	require => [
		Exec['install-composer'],
	],
}

exec { 'install-phpunit':
	command => 'sudo curl -o /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar && sudo chmod +x /usr/local/bin/phpunit',
	path => '/usr/local/bin/:/usr/bin/',
	timeout => 0,
	creates => '/usr/local/bin/phpunit',
	require => [
		Package['curl'],
		Package['php5-cli'],
	],
}


# ---------------------------------------------------
# Install Nginx
# ---------------------------------------------------

package { "nginx":
	ensure => present,
	require => Exec['apt-get update final'],
}

file { '/etc/nginx/nginx.conf':
	ensure => present,
	source => "/vagrant/manifests/files/nginx/nginx.conf",
	require => [
		Package['nginx'],
	],
	notify => Service['nginx'],
}

service { 'nginx':
	ensure => running,
	hasstatus => true,
	hasrestart => true,
	enable => true,
	require => Package['nginx'],
}

# ----------------------------------------------------
# ImageMagick
# ----------------------------------------------------

package{"imagemagick":
	ensure => present,
	require => Exec['apt-get update final'],
}
