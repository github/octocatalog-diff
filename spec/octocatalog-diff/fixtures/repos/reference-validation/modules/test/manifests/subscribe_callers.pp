class test::subscribe_callers {
  exec { 'subscribe caller 1':
    command   => '/bin/true',
    subscribe => Exec['subscribe target'],
  }

  exec { 'subscribe caller 2':
    command   => '/bin/true',
    subscribe => [
      Exec['subscribe target'],
      Exec['subscribe target 2']
    ]
  }

  exec { 'subscribe caller 3':
    command   => '/bin/true',
    subscribe => [
      Exec['subscribe caller 1'],
      Exec['subscribe target']
    ]
  }
}
