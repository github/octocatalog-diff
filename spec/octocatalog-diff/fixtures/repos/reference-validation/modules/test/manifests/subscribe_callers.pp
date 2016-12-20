class test::subscribe_callers {
  exec { 'subscribe caller':
    command   => '/bin/true',
    subscribe => Exec['subscribe target'],
  }
}
