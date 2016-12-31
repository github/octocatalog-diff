class test::notify_callers {
  exec { 'notify caller':
    notify => Test::Foo::Bar['notify target'],
  }
}
