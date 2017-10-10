class test::array2 {
  file { '/tmp/foo':
    source => [
      'puppet:///modules/test/foo-bar',
      'puppet:///modules/test/foo-old',
    ]
  }
}
