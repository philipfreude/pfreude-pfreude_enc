# @summary setup external node classifier for puppet
#
class pfreude_enc (
  String  $enc_dir           = '/etc/puppetlabs/puppet/enc',
  String  $enc_file_name     = 'enc.py',
  Boolean $manage_virtualenv = true,
  String  $postgres_user     = 'puppet',
  String  $postgres_password = '',
  Boolean $manage_puppetconf = true,
  String  $puppetconf        = '/etc/puppetlabs/puppet/puppet.conf'
) {
  file { $enc_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${enc_dir}/${enc_file_name}":
    ensure  => present,
    content => template('pfreude_enc/enc.py.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$enc_dir],
  }
  file { "${enc_dir}/settings.py":
    ensure  => present,
    content => template('pfreude_enc/settings.py.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  $requirements_txt = "${enc_dir}/requirements.txt"
  file { $requirements_txt:
    ensure  => present,
    content => file('pfreude_enc/requirements.txt'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File[$enc_dir]
  }
  if $manage_virtualenv and !defined(Package['virtualenv']) {
    class { 'python':
      virtualenv => 'present',
      dev        => 'present',
    }
  }
  if !defined(Package['python3-dev']) {
    package { 'python3-dev':
      ensure => installed,
    }
  }
  if !defined(Package['libpq-dev']) {
    package { 'libpq-dev':
      ensure => installed,
    }
  }
  python::virtualenv { "${enc_dir}/venv":
    ensure       => present,
    version      => '3.6',
    requirements => $requirements_txt,
    distribute   => false,
    owner        => 'root',
    cwd          => $enc_dir,
    require      => [File[$requirements_txt], Package['python3-dev'], Package['libpq-dev']],
  }

  if $manage_puppetconf {
    Ini_setting {
      path    => $puppetconf,
      ensure  => present,
      section => 'master',
      notify  => Service['puppetserver']
    }
    ini_setting { 'puppet-node-terminus':
      ensure  => present,
      section => 'master',
      setting => 'node_terminus',
      value   => 'exec',
    }
    ini_setting { 'puppet-external-nodes':
      ensure  => present,
      section => 'master',
      setting => 'external_nodes',
      value   => "${enc_dir}/${enc_file_name}",
    }
  }
}
