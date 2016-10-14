define system::user (
  $uid,
  $gid,
  $directory,
  $comment,
  $shell,
  $sshkey,
) {
  group { $name:
    ensure => present,
    gid    => $gid,
  }

  user { $name:
    ensure         => present,
    comment        => $comment,
    gid            => $gid,
    managehome     => true,
    purge_ssh_keys => true,
    shell          => $shell,
    uid            => $uid,
    require        => Group[$name],
  }

  ssh_authorized_key { "${name}@local":
    user    => $name,
    type    => 'ssh-rsa',
    key     => $sshkey,
    require => User[$name],
  }
}
