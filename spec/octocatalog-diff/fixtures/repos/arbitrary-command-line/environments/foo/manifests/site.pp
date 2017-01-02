node default {
  file { '/tmp/environment-foo-site':
    content => 'File created from environments/foo/manifests/site.pp',
  }
  include foo
}
