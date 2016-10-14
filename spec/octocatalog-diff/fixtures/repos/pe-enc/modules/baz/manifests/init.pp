class baz (
  $baz_param = 'not set'
) {
  file { '/tmp/baz':
    content => $baz_param,
  }
}
