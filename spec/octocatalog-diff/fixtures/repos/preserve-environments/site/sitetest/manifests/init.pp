class sitetest {
  file { '/tmp/sitetest':
    owner   => 'sitetest',
    content => $::environment,
  }

  file { '/tmp/sitetest-static.txt':
    source => 'puppet:///site/sitetest/sitetest-static.txt',
  }
}
