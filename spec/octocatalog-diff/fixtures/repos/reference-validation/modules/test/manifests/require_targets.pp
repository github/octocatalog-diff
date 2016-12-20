class test::require_targets {
  exec { 'require target':
    command => '/bin/true',
  }
}
