class test::subscribe_targets {
  exec { 'subscribe target':
    command => '/bin/true',
  }
}
