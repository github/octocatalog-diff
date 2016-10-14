class test {
  if env('FOO') {
    $foo = env('FOO')
  } else {
    $foo = 'undefined'
  }

  file { '/tmp/foo':
    content => "Foo is ${foo}",
  }
}
