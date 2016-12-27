class test {

  # Test resource
  file { '/tmp/test-main':
    content => 'it works',
  }
}
