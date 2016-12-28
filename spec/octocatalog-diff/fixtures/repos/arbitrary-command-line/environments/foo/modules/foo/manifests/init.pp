class foo {
  file { '/tmp/environment-foo-module':
    content => 'Created by environments/foo modules/foo',
  }
}
