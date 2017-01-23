class test (
  $var_one,
  $var_two = 'default',
) {
  file { '/tmp/one':
    content => $var_one,
  }

  file { '/tmp/two':
    content => $var_two,
  }

  file { '/tmp/three':
    content => 'three',
  }
}
