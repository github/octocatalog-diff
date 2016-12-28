node default {
  file { '/tmp/environment-production-site':
    content => 'File created from environments/production/manifests/site.pp',
  }
}
