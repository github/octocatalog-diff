class test {
  file { '/tmp/file':
    content => template('test/test.erb'),
  }
}
