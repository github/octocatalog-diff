class bar {
  file { '/tmp/bar':
    owner   => 'one',
    content => $::environment,
  }
}
