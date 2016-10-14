define mymodule::resource1 (
  $foo = 'file content',
  $bar = undef,
) {
  tag 'ignored_catalog_diff__mymodule__resource1'

  file { "/tmp/resource1/${name}":
    content => $foo,
  }
}
