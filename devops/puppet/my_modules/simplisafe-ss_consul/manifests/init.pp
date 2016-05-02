# == Class: ss_consul
#
# Full description of class ss_consul here.
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
#  class { 'ss_consul':
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
class ss_consul {
  $dev_initials = hiera('ss_dev_initials')

  ensure_packages('unzip')

  class { '::consul':
    version     => '0.5.2',
    config_hash => {
      'bootstrap_expect' => $::ss_consul_count,
      'client_addr'      => '0.0.0.0',
      'data_dir'         => '/opt/consul',
      'datacenter'       => "${dev_initials}-dev",
      'log_level'        => 'INFO',
      'server'           => true,
      'ui_dir'           => '/opt/consul/ui',
      'retry_join'       => [$::ss_consul_server],
      'bind_addr'        => $::internal_ip
    },
    require     => Package['unzip']
  }

  class { '::consul_template':
    version => '0.10.0',
  }

  service { 'firewalld':
    ensure => 'stopped',
    enable => false,
  }

  #if ( $::ec2_public_hostname) {
  #  $external_ip = $::ec2_public_hostname
  #}
  #else {
  #  $external_ip = $::ipaddress_eth1
  #}

  notify { 'consul_finished' :
    message => "CONSUL PUBLIC ADDRESS: http://${::external_ip}:8500",
    require => [
      Class['::consul'],
      Class['::consul_template'],
      Service['firewalld']
    ]
  }
}
