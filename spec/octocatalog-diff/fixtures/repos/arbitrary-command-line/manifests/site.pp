node default {
  file { '/tmp/foo':
    content => 'File created from manifests/site.pp',
  }
}
