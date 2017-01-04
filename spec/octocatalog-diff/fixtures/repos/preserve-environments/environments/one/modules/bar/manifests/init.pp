class bar (
  $param = '',
) {
  include sitetest

  file { '/tmp/bar':
    owner   => 'one',
    content => $::environment,
  }

  file { '/tmp/bar-static.txt':
    source => 'puppet:///modules/bar/bar-static.txt',
  }

  file { '/tmp/bar-param.txt':
    content => "one ${param}",
  }
}
