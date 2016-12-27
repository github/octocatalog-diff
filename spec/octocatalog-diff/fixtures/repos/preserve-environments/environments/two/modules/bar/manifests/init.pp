class bar {
  include sitetest

  file { '/tmp/bar':
    owner   => 'two',
    content => $::environment,
  }
}
