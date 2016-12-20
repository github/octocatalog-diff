class test::notify_callers {
  exec { 'notify caller':
    command => '/bin/true',
    notify  => Exec['notify target'],
  }
}
