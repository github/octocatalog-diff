class test::array1 {
  file { '/tmp/foo':
    source => [
      'puppet:///modules/test/foo-new',
      'puppet:///modules/test/foo-old',
    ]
  }
}
