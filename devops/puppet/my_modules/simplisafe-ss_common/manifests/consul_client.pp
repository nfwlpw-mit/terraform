# == Class: ss_common::consul_client

class ss_common::consul_client {
  $dev_initials = hiera('ss_dev_initials')

  ensure_packages('unzip')

  class { '::consul':
    version     => '0.5.2',
    config_hash => {
      'data_dir'           => '/opt/consul',
      'datacenter'         => "${dev_initials}-dev",
      'log_level'          => 'INFO',
      'retry_join'         => [$::ss_consul_server],
      'bind_addr'          => $::internal_ip,
      'leave_on_terminate' => true
    },
    require     => Package['unzip']
  }

  class { '::consul_template':
    version => '0.10.0',
  }
}
