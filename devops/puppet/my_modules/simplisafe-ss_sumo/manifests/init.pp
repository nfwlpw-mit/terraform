class ss_sumo (
  $sumo_exec       = $ss_sumo::params::sumo_exec,
  $sumo_short_arch = $ss_sumo::params::sumo_short_arch,
) inherits ss_sumo::params {

  include ss_sumo::config
}
