# @summary setup external node classifier for puppet
#
class pfreude_enc (
  String $enc_dir            = '/etc/puppetlabs/puppet/enc/',
  String $enc_file_name      = 'enc.py',
  String $postgres_user      = 'puppet',
  String $postgres_password  = '',
  Boolean $manage_puppetconf = true,
  String $puppetconf         = '/etc/puppetlabs/puppet/puppet.conf'
) {

  file { $enc_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${enc_dir}/${enc_file_name}":
    ensure  => present,
    content => file('pfreude_enc/enc.py'),
    require => File[$enc_dir],
  }

  if $manage_puppetconf {
    Ini_setting {
      path    => $puppetconf,
      ensure  => present,
      section => 'master'
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
      value   => '/etc/puppetlabs/puppet/enc/enc.py',
    }
  }
}
