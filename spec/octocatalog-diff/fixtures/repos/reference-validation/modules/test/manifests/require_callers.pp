class test::require_callers {
  exec { 'require caller':
    command => '/bin/true',
    require => Exec['require target'],
  }

  exec { 'require caller 2':
    command => '/bin/true',
    require => Exec['require caller'],
  }

  exec { ['require caller 3', 'require caller 4']:
    command => '/bin/true',
    require => [
      Exec['require caller'],
      Exec['require target'],
    ]
  }
}
