class test {
  file { '/tmp/ipaddress':
    content => $::ipaddress,
  }

  if $foofoo {
    file { '/tmp/foofoo':
      content => $foofoo
    }
  }
}
