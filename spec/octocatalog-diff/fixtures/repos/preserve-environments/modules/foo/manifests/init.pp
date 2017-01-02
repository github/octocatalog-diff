class foo {
  file { '/tmp/foo':
    owner   => 'foo',
    content => $::environment,
  }

  file { '/tmp/foo-static.txt':
    source => 'puppet:///modules/foo/foo-static.txt',
  }
}
