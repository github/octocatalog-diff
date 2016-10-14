class test {
  if defined('$top_level_param') {
    file { '/tmp/bar':
      content => $::top_level_param,
    }
  } else {
    file { '/tmp/bar':
      ensure => absent,
    }
  }
}
