# == Class: ss_mongo
#
# Deploy mongo and listen on all ports.
#
# === Authors
#
# Kevin Cormier <kevin.cormier@simplisafe.com
#
# === Copyright
#
# Copyright 2014 SimpliSafe, unless otherwise noted.
#
class ss_mongo {
  include ::ss_common::consul_client

  ::consul::service { 'mongo':
    port    => 27017
  }

  service { 'firewalld':
    ensure => 'stopped',
    enable => false,
  }

  class {'::mongodb::globals':
    manage_package_repo => true,
    bind_ip             => '0.0.0.0',
  }->
  class {'::mongodb::server': }->
  class {'::mongodb::client': }

  exec { 'bootstrap mongo':
    command => '/usr/bin/mongo --eval \'db.clients.insert( { "name" : "Test Client", "clientId" : "testClient", "clientSecret" : "eggs" } )\' ssauth',
    require => Class['::mongodb::client']
  }
}
