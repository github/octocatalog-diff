class test::before_targets {
  exec { 'before target':
    command => '/bin/true',
  }
}
