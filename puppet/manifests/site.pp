$packages = [ 'curl',
              'git',
              'libsasl2-dev',
              'python-dev',
              'libssl-dev',
              'libldap2-dev',
              'freetds-dev',
              'libjpeg62-dev',
              'libmariadbclient18',
              'libmariadbclient-dev',
              'unixodbc-dev' ]

class { 'apt': }
apt::source { 'mariadb':
  location    => 'http://ftp.osuosl.org/pub/mariadb/repo/10.0/ubuntu',
  repos       => 'main',
  key         => 'cbcb082a1bb943db',
  key_server  => 'pgp.mit.edu',
}

class { '::rabbitmq': }

$users = {
  'rooibos@localhost' => {
    ensure        => 'present',
    password_hash => undef,
  }
}

$grants = {
  'rooibos@localhost/rooibos' => {
    ensure     => 'present',
    privileges => ['ALL'],
    table      => 'rooibos.*',
    user       => 'rooibos@localhost',
  }
}

$databases = {
  'rooibos' => {
    ensure  => 'present',
    charset => 'utf8',
  }
}

class { '::mysql::server':
  root_password => undef,
  package_name  => 'mariadb-server-10.0',
  users         => $users,
  databases     => $databases,
  grants        => $grants,
  require       => Apt::Source['mariadb'],
}

class { 'docker': }

docker::image { 'wmit/mdid-solr':
  require => Class['docker'],
}

docker::run { 'mdid-solr':
  image    => 'wmit/mdid-solr',
  ports    => ['8983:8983'],
  use_name => true,
  volumes  => ['/var/solr-mdid/data:/opt/solr/config/rooibos/data'],
  require  => Docker::Image['wmit/mdid-solr'],
}

package { $packages:
  ensure  => installed,
  require => Apt::Source['mariadb'],
}

exec { 'install-pip':
  command => 'curl https://bootstrap.pypa.io/get-pip.py | python',
  path    => ['/usr/bin', '/usr/sbin'],
  creates => '/usr/local/bin/pip',
  require => Package['curl'],
}

file { '/usr/bin/pip':
  ensure  => link,
  target  => '/usr/local/bin/pip',
  require => Exec['install-pip'],
}

package { 'virtualenv':
  ensure   => present,
  provider => 'pip',
  require  => File['/usr/bin/pip'],
}

file { '/vagrant/rooibos/rooibos/settings_local.py':
  ensure => present,
  source => '/vagrant/rooibos/rooibos/settings_local_template.py',
}

class { 'nginx':
  confd_purge => true,
  vhost_purge => true,
}

nginx::resource::upstream { 'gunicorn-mdid':
  ensure  => present,
  members => ['localhost:8000'],
}

nginx::resource::vhost { 'mdid':
  ensure => present,
  proxy  => 'http://gunicorn-mdid',
}

nginx::resource::location { 'mdid-static':
  ensure         => present,
  vhost          => 'mdid',
  location       => '/static',
  location_alias => '/vagrant/rooibos/rooibos/static',
}

file { '/vagrant/rooibos/uploads':
  ensure => directory,
}

nginx::resource::location { 'mdid-uploads':
  ensure         => present,
  vhost          => 'mdid',
  location       => '/uploads',
  location_alias => '/vagrant/rooibos/uploads',
  require        => File['/vagrant/rooibos/uploads'],
}
