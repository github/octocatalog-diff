class test::array3 {
  file { '/tmp/foo':
    source => [
      'puppet:///modules/test/foo-bar',
      'puppet:///modules/test/foo-baz',
    ]
  }
}
