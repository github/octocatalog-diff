class sitetest {
  file { '/tmp/sitetest':
    source => 'puppet:///modules/sitetest/tmp/sitetest',
  }
}
