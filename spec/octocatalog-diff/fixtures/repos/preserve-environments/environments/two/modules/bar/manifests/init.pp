class bar {
  file { '/tmp/bar':
    owner   => 'two',
    content => $::environment,
  }
}
