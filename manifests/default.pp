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

package { 'vim':
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

package { 'python-software-properties':
  ensure => present,
  require => Exec['apt-get update'],
}

exec { 'Import repo signing key to apt keys':
  path   => '/usr/bin:/usr/sbin:/bin',
  command     => 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C',
  unless      => 'apt-key list | grep E5267A6C',
  require => Exec['aptitude upgrade'],
}

exec { 'Import repo signing key to apt keys 2':
  path   => '/usr/bin:/usr/sbin:/bin',
  command     => 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ABF5BD827BD9BF62',
  unless      => 'apt-key list | grep ABF5BD827BD9BF62',
  require => Exec['aptitude upgrade'],
}

exec { "Import repo signing key to apt keys 3":
  path   => "/usr/bin:/usr/sbin:/bin",
  command     => "wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -",
  require => Exec['aptitude upgrade'],
}

exec { 'apt-get update':
  command => '/usr/bin/sudo apt-get update',
  require => Exec['aptitude upgrade'],
}

exec { 'adding new nginx':
  command => '/usr/bin/sudo echo "deb http://nginx.org/packages/ubuntu/ precise nginx" > /etc/apt/sources.list.d/nginx.list',
  creates => '/etc/apt/sources.list.d/nginx.list',
  require => Package['python-software-properties'],
  unless => '/usr/bin/test -f /etc/apt/sources.list.d/nginx.list',
}

exec { 'adding ppa:ondrej/php5':
  command => '/usr/bin/sudo add-apt-repository -y ppa:ondrej/php5',
  creates => '/etc/apt/sources.list.d/ondrej-php5-precise.list',
  require => Package['python-software-properties'],
  unless => '/usr/bin/test -f /etc/apt/sources.list.d/ondrej-php5-precise.list'
}

exec { 'adding ppa:chris-lea/redis-server':
  command => '/usr/bin/sudo add-apt-repository -y ppa:chris-lea/redis-server',
  creates => '/etc/apt/sources.list.d/chris-lea-redis-server-precise.list',
  require => Package['python-software-properties'],
  unless => '/usr/bin/test -f /etc/apt/sources.list.d/chris-lea-redis-server-precise.list'
}

exec { 'adding hhvm sources.list':
  command => '/usr/bin/sudo echo "deb http://dl.hhvm.com/ubuntu precise main" > /etc/apt/sources.list.d/hhvm.list',
  require => Package['python-software-properties'],
  creates => '/etc/apt/sources.list.d/hhvm.list',
  unless => '/usr/bin/test -f /etc/apt/sources.list.d/hhvm.list'
}

exec { 'apt-get update final':
  command => '/usr/bin/sudo apt-get update',
  require => [
    Package['python-software-properties'],
    Exec['adding new nginx'],
    Exec['adding ppa:ondrej/php5'],
    Exec['adding ppa:chris-lea/redis-server'],
    Exec['adding hhvm sources.list']
  ]
}

# ---------------------------------------------------
# Install MySQL
# ---------------------------------------------------
package { 'mysql-server':
  ensure => present,
  require => Exec['apt-get update final']
}

service { 'mysql':
  ensure => running,
  hasstatus => true,
  hasrestart => true,
  enable => true,
  require => Package['mysql-server']
}

exec { 'mysql-root-password':
  command => '/usr/bin/mysqladmin -u root password vagrant',
  onlyif => '/usr/bin/mysql -u root mysql -e "SHOW DATABASES;"',
  require => Package['mysql-server'],
}

exec { 'mysql-root-create-xhprof-db':
  command => '/usr/bin/mysql -uroot -pvagrant -e "CREATE DATABASE IF NOT EXISTS xhprof CHARACTER SET utf8 COLLATE utf8_general_ci;"',
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
# Install HHVM
# ---------------------------------------------------
package { 'hhvm':
  ensure => installed,
  require => Exec['apt-get update final'],
}

service { 'hhvm-fastcgi':
  ensure => running,
  hasstatus => true,
  hasrestart => true,
  enable => true,
  require => [
    Package['hhvm'],
    File['/var/log/hhvm'],
    File['/var/run/hhvm'],
    File['/etc/hhvm/server.hdf'],
    File['/etc/default/hhvm-fastcgi'],
    File['/etc/init.d/hhvm-fastcgi']
  ],
}

file { '/etc/hhvm/server.hdf':
  ensure => file,
  source => '/vagrant/manifests/files/hhvm/server.hdf',
  owner  => 'root',
  group  => 'root',
  mode   => 0775,
  require => Package['hhvm'],
  notify => Service['hhvm-fastcgi']
}

file { '/etc/default/hhvm-fastcgi':
  ensure => file,
  source => '/vagrant/manifests/files/hhvm/default',
  owner  => 'root',
  group  => 'root',
  mode   => 0775,
  require => Package['hhvm'],
  notify => Service['hhvm-fastcgi']
}

file { '/etc/init.d/hhvm-fastcgi':
  ensure => file,
  source => '/vagrant/manifests/files/hhvm/init',
  owner  => 'root',
  group  => 'root',
  mode   => 0775,
  require => Package['hhvm'],
  notify => Service['hhvm-fastcgi']
}

file { '/var/log/hhvm':
  ensure => 'directory',
  owner  => 'www-data',
  group  => 'www-data',
  mode   => 0755,
}

file { '/var/run/hhvm':
  ensure => 'directory',
  owner  => 'www-data',
  group  => 'www-data',
  mode   => 0755,
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

package { 'graphviz':
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
  source => '/vagrant/manifests/files/php/www.conf',
  require => Package['php5-fpm'],
  notify => Service['php5-fpm']
}

file { '/etc/php5/fpm/conf.d/90-vagrant.ini':
  ensure => present,
  source => '/vagrant/manifests/files/php/90-vagrant.ini',
  require => Package['php5-fpm'],
  notify => Service['php5-fpm'],
}

file { '/etc/php5/cli/conf.d/90-vagrant.ini':
  ensure => present,
  source => '/vagrant/manifests/files/php/90-vagrant.ini',
  require => Package['php5-cli']
}

# ---------------------------------------------------
# Install Composer
# ---------------------------------------------------
exec { 'install-composer':
  command => 'curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer',
  path => '/usr/local/bin/:/usr/bin/:/bin/',
  timeout => 0,
  creates => '/usr/local/bin/composer',
  require => [
    Package['curl'],
    Package['php5-cli']
  ]
}

exec { 'selfupdate-composer':
  command => 'sudo composer self-update',
  path => '/usr/local/bin/:/usr/bin/',
  require => Exec['install-composer']
}

# ---------------------------------------------------
# Install PHP Unit
# ---------------------------------------------------
exec { 'install-phpunit':
  command => 'sudo curl -o /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar && sudo chmod +x /usr/local/bin/phpunit',
  path => '/usr/local/bin/:/usr/bin/',
  timeout => 0,
  creates => '/usr/local/bin/phpunit',
  require => [
    Package['curl'],
    Package['php5-cli']
  ]
}

# ---------------------------------------------------
# Install Nginx
# ---------------------------------------------------
package { 'nginx':
  ensure => present,
  require => Exec['apt-get update final']
}

file { '/etc/nginx/nginx.conf':
  ensure => present,
  source => '/vagrant/manifests/files/nginx/nginx.conf',
  require => Package['nginx'],
  notify => Service['nginx']
}

file { '/etc/nginx/mime.types':
  ensure => present,
  source => '/vagrant/manifests/files/nginx/mime.types',
  require => Package['nginx'],
  notify => Service['nginx']
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
package{'imagemagick':
  ensure => present,
  require => Exec['apt-get update final'],
}
