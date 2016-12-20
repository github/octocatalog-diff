class test::require_callers {
  exec { 'require caller':
    command => '/bin/true',
    require => Exec['require target'],
  }
}
