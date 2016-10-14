class foo (
  $foo_param = 'not set',
) {
  file { '/tmp/foo':
    content => $foo_param,
  }
}
