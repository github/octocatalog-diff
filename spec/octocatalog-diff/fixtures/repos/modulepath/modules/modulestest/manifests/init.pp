class modulestest {
  file { '/tmp/modulestest':
    source => 'puppet:///modules/modulestest/tmp/modulestest',
  }
}
