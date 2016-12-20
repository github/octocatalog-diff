class test {

  # Test resource
  file { '/tmp/test-main':
    content => 'it works',
  }

  # Targets for require, before, subscribe, notify
  exec { 'target 1':
    command => '/bin/true',
  }

  exec { 'target 2':
    command => '/bin/true',
  }

  exec { 'target 3':
    command => '/bin/true',
  }

  exec { 'target 4':
    command => '/bin/true',
  }
}
