class system::root_ssh_keys (
  $keys = hiera_array('system::root_ssh_keys::keys', []),
) {
  file { '/root/.ssh':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }
  system::root_ssh_key { $keys:
    require => File['/root/.ssh'],
  }
}
