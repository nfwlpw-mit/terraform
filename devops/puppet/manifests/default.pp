if versioncmp($::puppetversion,'3.6.1') >= 0 {

  $allow_virtual_packages = hiera('allow_virtual_packages',true)

  Package {
    allow_virtual => $allow_virtual_packages,
  }
}

notice("SIMPLISAFE CLASS ${::ss_class}")

include ss_common

file { '/etc/ssh/git_rsa':
  ensure => 'file',
  source => '/vagrant/config/ssh_keys/id_rsa',
  owner  => 'root',
  group  => 'root',
  mode   => '0700',
}

sshkey { 'github.com':
  ensure => 'present',
  key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==',
  type   => 'ssh-rsa',
}

package { "vim":
  ensure        => "installed",
#  allow_virtual => true,
}

$augeastools = $::operatingsystem ? {
        Ubuntu  => 'augeas-tools',
        default => 'augeas',
    }

package { $augeastools:
  ensure => "installed",
  alias  => "augeas"
}

package { "git":
  ensure => "installed",
}

node 'api' {
  include ss_api
}

node 'consul' {
  include ss_consul
}

#node 'webapp' {
#  include ss_webapp
#}

node 'mysql' {
  include ss_mysql
}

node 'mongo' {
  include ss_mongo
}

node 'redis' {
  include ss_redis
}

node 'drupal' {
  include ss_drupal
}

node 'media' {
  include ss_media
}

node 'backend' {
  include ss_backend
}

node 'sarlacc' {
  include ss_sarlacc
}

node 'asterisk' {
  include ss_asterisk
}

node default {
  case "${::ss_class}" {
    'consul'  : { include ss_consul }
    'mysql'   : { include ss_mysql }
    'mongo'   : {
      include ss_mongo

      package { "rng-tools":
        ensure => "installed"
      }

      service { "rngd":
        ensure  => "running",
        enable  => true,
        require => Package['rng-tools']
      }
    }
    'redis'   : { include ss_redis }
    'api'     : {
      include ss_api

      package { "rng-tools":
        ensure => "installed"
      }

      service { "rngd":
        ensure  => "running",
        enable  => true,
        require => Package['rng-tools']
      }
    }
    'backend' : { include ss_backend }
    'webapp'  : { include ss_webapp }
    'media'   : { include ss_media }
    'drupal'  : { include ss_drupal }
    'asterisk': { include ss_asterisk }
    'sarlacc' : { include ss_sarlacc, pip}
  }
}
