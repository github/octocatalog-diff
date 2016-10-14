define mymodule::resource2 (
  $foo = 'file content',
  $bar = undef,
) {
  file { "/tmp/resource2/${name}":
    content => $foo,
  }

  file { "/tmp/ignored/${name}":
    content => 'old repo',
    tag     => ['ignored_catalog_diff'],
  }

  file { "/tmp/old-file/ignored/${name}":
    content => 'old repo',
    tag     => ['ignored_catalog_diff'],
  }
}
