# @summary setup external node classifier for puppet
#
# @param ensure
#   global toggle for the state of the external node classifier
# @param enc_dir
#   directory for external node classifier
# @param enc_file_name
#   filename of external node classifier
# @param manage_virtualenv
#   manage virtualenv
# @param postgres_host
#   postgres host
# @param postgres_database
#   postgres database
# @param postgres_user
#   postgres user
# @param postgres_password
#   postgres password
# @param manage_puppetconf
#   manage puppet.conf
# @param puppetconf
#   path to puppet.conf
class pfreude_enc (
  Enum['present', 'absent'] $ensure            = present,
  String                    $enc_dir           = '/etc/puppetlabs/puppet/enc',
  String                    $enc_file_name     = 'enc.py',
  Boolean                   $manage_virtualenv = true,
  String                    $postgres_host     = '127.0.0.1',
  String                    $postgres_database = 'puppet',
  String                    $postgres_user     = 'puppet',
  String                    $postgres_password = undef,
  Boolean                   $manage_puppetconf = true,
  String                    $puppetconf        = '/etc/puppetlabs/puppet/puppet.conf',
) {
  if $manage_virtualenv and !defined(Package['virtualenv']) {
    class { 'python':
      dev => 'present',
    }
  }
  if !defined(Package['libpq-dev']) {
    package { 'libpq-dev':
      ensure => installed,
    }
  }
  if $ensure == 'present' {
    file { $enc_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    file { "${enc_dir}/${enc_file_name}":
      content => template('pfreude_enc/enc.py.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$enc_dir],
    }
    file { "${enc_dir}/settings.py":
      content => template('pfreude_enc/settings.py.erb'),
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '0600',
    }
    $requirements_txt = "${enc_dir}/requirements.txt"
    file { $requirements_txt:
      content => file('pfreude_enc/requirements.txt'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
    python::pyvenv { "${enc_dir}/venv":
      ensure => present,
    }
    python::requirements { $requirements_txt:
      virtualenv => "${enc_dir}/venv",
      require    => [File[$requirements_txt], Package['libpq-dev']],
    }
  } else {
    file { $enc_dir:
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
    }
  }

  if $manage_puppetconf {
    Ini_setting {
      path    => $puppetconf,
      ensure  => $ensure,
      section => 'master',
      notify  => Service['puppetserver'],
    }
    ini_setting { 'puppet-node-terminus':
      setting => 'node_terminus',
      value   => 'exec',
    }
    ini_setting { 'puppet-external-nodes':
      setting => 'external_nodes',
      value   => "${enc_dir}/${enc_file_name}",
    }
  }
}
