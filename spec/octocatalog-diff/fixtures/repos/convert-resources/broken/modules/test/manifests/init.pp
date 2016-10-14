class test {
  file { '/tmp/foo1':
    source => 'puppet:///modules/test/foo-new',
  }

  file { '/tmp/foo2':
    source => 'puppet:///modules/test/foo-old',
  }
}
