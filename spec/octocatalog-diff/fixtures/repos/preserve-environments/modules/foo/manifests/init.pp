class foo {
  file { '/tmp/foo':
    owner   => 'foo',
    content => $::environment,
  }
}
