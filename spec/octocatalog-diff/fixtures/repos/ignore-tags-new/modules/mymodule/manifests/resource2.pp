define mymodule::resource2 (
  $foo = 'file content',
  $bar = undef,
) {
  file { "/tmp/resource2/${name}":
    content => $foo,
  }

  file { "/tmp/ignored/${name}":
    content => 'new repo',
    tag     => ['ignored_catalog_diff'],
  }

  file { "/tmp/new-file/ignored/${name}":
    content => 'new repo',
    tag     => ['ignored_catalog_diff'],
  }
}
