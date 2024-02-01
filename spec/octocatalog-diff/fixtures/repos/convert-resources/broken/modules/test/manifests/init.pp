class test {
  file { '/tmp/foo1':
    tag    => ['_convert_file_resources_foo1_'],
    source => 'puppet:///modules/test/foo-new',
  }

  file { '/tmp/foo2':
    tag    => ['_convert_file_resources_foo2_'],
    source => 'puppet:///modules/test/foo-old',
  }
}
