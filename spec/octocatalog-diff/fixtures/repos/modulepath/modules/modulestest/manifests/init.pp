class modulestest {
  file { '/tmp/modulestest':
    source => 'puppet:///modules/modulestest/tmp/modulestest',
  }

  file { '/tmp/foobaz':
    ensure  => directory,
    source  => 'puppet:///modules/modulestest/foo',
    recurse => true,
  }
}
