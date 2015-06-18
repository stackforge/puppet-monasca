# == Class: monasca::alarmdefs
#
# Class for bootstrapping monasca alarm definitions
#
# === Parameters:
#
# [*alarm_definition_config_source*]
#   location of alarm definitions to bootstrap in mysql database
#
# [*admin_username*]
#   name of the monasca admin user
#
# [*admin_password*]
#   password of the monasca admin user
#
# [*api_server_url*]
#   monasca api server endpoint
#
# [*auth_url*]
#   keystone endpoint
#
# [*project_name*]
#   keystone project name to bootstrap alarm definitions for
#
# [*virtual_env*]
#   location of python virtual environment to install to
#
# [*install_python_deps*]
#   flag for whether or not to install python dependencies
#
# [*python_dep_ensure*]
#   flag for whether or not to ensure/update python dependencies
#
class monasca::alarmdefs(
  $alarm_definition_config_source = 'puppet:///modules/monasca/alarm_definition_config.json',
  $admin_username = 'monasca-admin',
  $admin_password = undef,
  $api_server_url = undef,
  $auth_url = undef,
  $project_name = undef,
  $virtual_env = '/var/www/monasca-alarmdefs',
  $install_python_deps     = true,
  $python_dep_ensure       = 'present',
)
{
  include ::monasca::params

  $alarm_definition_config = '/tmp/alarm_definition_config.json'
  $script_name = 'bootstrap-alarm-definitions.py'
  $script = "${virtual_env}/bin/${script_name}"

  if $install_python_deps {
    package { ['python-virtualenv', 'python-dev']:
      ensure => $python_dep_ensure,
      before => Python::Virtualenv[$virtual_env],
    }
  }

  python::virtualenv { $virtual_env :
    owner   => 'root',
    group   => 'root',
    before  => [Exec[$script], File[$script]],
    require => [Package['python-virtualenv'],Package['python-dev']],
  }

  python::pip { 'python-keystoneclient' :
    virtualenv => $virtual_env,
    owner      => 'root',
    require    => Python::Virtualenv[$virtual_env],
    before     => Exec[$script],
  }

  python::pip { 'python-monascaclient' :
    virtualenv => $virtual_env,
    owner      => 'root',
    require    => Python::Virtualenv[$virtual_env],
    before     => Exec[$script],
  }

  file { $script:
    ensure  => file,
    content => template("monasca/${script_name}.erb"),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { $alarm_definition_config:
    ensure => file,
    source => $alarm_definition_config_source,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  exec { $script:
    subscribe   => [File[$script], File[$alarm_definition_config]],
    path        => '/bin:/sbin:/usr/bin:/usr/sbin:/tmp',
    cwd         => "${virtual_env}/bin",
    user        => 'root',
    group       => 'root',
    environment => ["OS_AUTH_URL=${auth_url}",
                    "OS_USERNAME=${admin_username}",
                    "OS_PASSWORD=${admin_password}",
                    "OS_PROJECT_NAME=${project_name}",
                    "MONASCA_API_URL=${api_server_url}"],
    refreshonly => true,
    require     => Service['monasca-api'],
  }
}
