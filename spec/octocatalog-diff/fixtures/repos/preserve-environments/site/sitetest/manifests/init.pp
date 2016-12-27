class sitetest {
  file { '/tmp/sitetest':
    owner   => 'sitetest',
    content => $::environment,
  }
}
