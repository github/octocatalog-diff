class test {
  file { '/tmp/foo':
    content => template('test/foo.erb'),
  }
}
