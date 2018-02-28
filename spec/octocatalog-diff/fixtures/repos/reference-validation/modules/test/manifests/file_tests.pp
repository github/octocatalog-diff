class test::file_tests {
  file { '/foo':
    ensure => directory,
  }

  file { '/bar':
    ensure  => directory,
    require => File['/foo/'],
  }
}
