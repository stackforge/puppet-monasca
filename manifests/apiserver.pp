#
# Class for the monasca api server
#
class monasca::apiserver(
  $blobmirror = undef,
  $mon_api_build_ver = undef,
  $mon_pers_build_ver = undef,
  $mon_thresh_build_ver = undef,
  $mon_api_deb = undef,
  $mon_pers_deb = undef,
  $mon_thresh_deb = undef,
){
  ensure_resource('package', 'openjdk-7-jre', { ensure => 'present' })

  $api_fetch_url = "http://${blobmirror}/repos/monasca/monasca_api"
  $pers_fetch_url = "http://${blobmirror}/repos/monasca/monasca_persister"
  $thresh_fetch_url = "http://${blobmirror}/repos/monasca/monasca_thresh"
  $latest_api_deb = "/tmp/${mon_api_deb}"
  $latest_pers_deb = "/tmp/${mon_pers_deb}"
  $latest_thresh_deb = "/tmp/${mon_thresh_deb}"

  wget::fetch { "${api_fetch_url}/${mon_api_build_ver}/${mon_api_deb}":
    destination => $latest_api_deb,
    timeout     => 300,
    before      => [Package['install-api'],File[$latest_api_deb]],
  }

  wget::fetch { "${pers_fetch_url}/${mon_pers_build_ver}/${mon_pers_deb}":
    destination => $latest_pers_deb,
    timeout     => 300,
    before      => [Package['install-persister'], File[$latest_pers_deb]],
  }

  wget::fetch { "${thresh_fetch_url}/${mon_thresh_build_ver}/${mon_thresh_deb}":
    destination => $latest_thresh_deb,
    timeout     => 300,
    before      => [Package['install-thresh'], File[$latest_thresh_deb]],
  }

  file { $latest_api_deb:
    ensure => present,
  }

  file { $latest_pers_deb:
    ensure => present,
  }

  file { $latest_thresh_deb:
    ensure => present,
  }

  package { 'monasca-api':
    ensure   => latest,
    provider => dpkg,
    source   => $latest_api_deb,
    alias    => 'install-api',
  }

  package { 'monasca-persister':
    ensure   => latest,
    provider => dpkg,
    source   => $latest_pers_deb,
    alias    => 'install-persister',
  }

  package { 'monasca-thresh':
    ensure   => latest,
    provider => dpkg,
    source   => $latest_thresh_deb,
    alias    => 'install-thresh',
  }

  # Remove any old debs (puppet won't delete current resources)
  tidy { '/tmp':
    matches => 'monasca*.deb',
    recurse => true,
  }
}
