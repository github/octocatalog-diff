define test::foo::bar {
  exec { "test::foo::bar ${name}":
    command => '/bin/true',
  }
}
