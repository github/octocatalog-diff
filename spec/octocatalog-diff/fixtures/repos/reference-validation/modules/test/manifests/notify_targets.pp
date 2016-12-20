class test::notify_targets {
  exec { 'notify target':
    command => '/bin/true',
  }
}
