# == Class: ss_redis
#
# Full description of class ss_redis here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'ss_redis':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class ss_redis {
  include ::ss_common::consul_client

  ::consul::service { 'redis':
    port    => 6379
  }

  package { 'epel-release':
    ensure => 'installed'
  }

  package { 'redis':
    ensure  => 'installed',
    require => Package['epel-release']
  }

  exec { 'set redis bind ip':
    command => '/usr/bin/sed -i "s/127.0.0.1/0.0.0.0/" /etc/redis.conf',
    user    => 'root',
    require => Package['redis']
  }

  service { 'redis':
    ensure  => 'running',
    enable  => true,
    require => Exec['set redis bind ip']
  }
}
