class bar {
  include sitetest

  file { '/tmp/bar':
    owner   => 'one',
    content => $::environment,
  }

  file { '/tmp/bar-static.txt':
    source => 'puppet:///modules/bar/bar-static.txt',
  }
}
