class bar {
  include sitetest

  file { '/tmp/bar':
    owner   => 'one',
    content => $::environment,
  }
}
