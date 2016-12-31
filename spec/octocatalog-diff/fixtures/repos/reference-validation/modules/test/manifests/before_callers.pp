class test::before_callers {
  exec { 'before caller':
    command => '/bin/true',
    before  => Exec['before target'],
  }
}
