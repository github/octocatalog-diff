class bar {
  if defined('$bar_variable') {
    file { '/tmp/bar':
      content => $::bar_variable,
    }
  } else {
    file { '/tmp/bar':
      content => 'not set',
    }
  }
}
