define system::root_ssh_key {
  $key_sha1 = sha1($name)
  ssh_authorized_key { "root@${key_sha1}":
    user => 'root',
    type => 'ssh-rsa',
    key  => $name,
  }
}
