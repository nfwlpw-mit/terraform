# == Class: ss_mysql
#
# Used to deploy mysql/mariadb and load the simplisafe_LIVE database.
#
# === Authors
#
# Kevin Cormier <kevin.cormier@.com>
#
# === Copyright
#
# Copyright 2014 SimpliSafe, unless otherwise noted.
#
class ss_mysql{
  include ::ss_common::consul_client

  ::consul::service { 'mysql':
    port    => 3306
  }

  service { 'firewalld':
    ensure => 'stopped',
    enable => false,
  }

  $override_options = {
    'mysqld' => {
      'bind-address'         => '0.0.0.0',
      'datadir'              => '/mnt/mysql_data',
      'socket'               => '/mnt/mysql_data/mysql.sock',
      'myisam_repair_thread' => '4'
    },
    'mysqld_safe' => {
      'socket'    => '/mnt/mysql_data/mysql.sock'
    },
    'client' => {
      'socket'    => '/mnt/mysql_data/mysql.sock'
    }
    
  }
  class { '::mysql::server':
    override_options => $override_options
  }

  include '::mysql::client'

  exec { 'check_sql_exists':
    command => '/bin/false',
    unless  =>
      '/usr/bin/test -f /vagrant/database/simplisafe_LIVE.sql \
        -a -r /vagrant/database/simplisafe_LIVE.sql',
  }

  mysql::db { 'simplisafe_LIVE':
    user           => 'drupal',
    password       => 'ih2bsass',
    host           => '%',
    sql            => '/vagrant/database/simplisafe_LIVE.sql',
    import_timeout => 7200,
    require        => Exec['check_sql_exists'],
  }
}
