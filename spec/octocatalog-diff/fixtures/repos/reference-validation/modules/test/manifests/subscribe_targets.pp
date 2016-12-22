class test::subscribe_targets {
  exec { 'subscribe target':
    command => '/bin/true',
  }

  exec { 'subscribe target 2':
    command => '/bin/true',
  }
}
