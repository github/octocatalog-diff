define mymodule::resource1 (
  $foo = 'file content',
  $bar = undef,
) {
  file { "/tmp/resource1/${name}":
    content => $foo,
  }
}
