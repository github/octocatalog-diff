class bar ( $parameter ) {
  file { '/tmp/template/different-yaml.yaml':
    content => template('bar/different-yaml.erb')
  }

  file { "/tmp/template/different-yaml-${parameter}.yaml":
    content => template('bar/different-yaml.erb')
  }

  file { '/tmp/template/identical-yaml.yaml':
    content => template('bar/identical-yaml.erb')
  }

  file { '/tmp/template/not-yaml.yaml':
    content => '{ "title": "This is not YAML" }'
  }

  file { '/tmp/template/not-yaml-2.yaml':
    content => template('bar/not-yaml.erb')
  }

  file { "/tmp/template/not-yaml-${parameter}.yaml":
    content => template('bar/not-yaml.erb')
  }

  file { '/tmp/template/similar-yaml.yaml':
    content => template('bar/similar-yaml.erb')
  }

  file { '/tmp/template/similar-yaml.json':
    content => template('bar/similar-yaml.erb')
  }

  file { '/tmp/template/unparseable-yaml.yaml':
    content => template('bar/unparseable-yaml.erb'),
  }

  file { '/tmp/template/unparseable-yaml-2.yaml':
    content => template('bar/unparseable-yaml-2.erb'),
  }

  file { "/tmp/template/unparseable-yaml-${parameter}.yaml":
    content => template('bar/unparseable-yaml-2.erb'),
  }

  file { '/tmp/static/different-yaml.yaml':
    source => "puppet:///modules/bar/different-yaml.${parameter}"
  }

  file { "/tmp/static/different-yaml-${parameter}.yaml":
    source => "puppet:///modules/bar/different-yaml.${parameter}"
  }

  file { '/tmp/static/identical-yaml.yaml':
    source => 'puppet:///modules/bar/identical-yaml',
  }

  file { '/tmp/static/not-yaml.yaml':
    source => 'puppet:///modules/bar/not-yaml.default',
  }

  file { '/tmp/static/not-yaml-2.yaml':
    source => "puppet:///modules/bar/not-yaml.${parameter}",
  }

  file { "/tmp/static/not-yaml-${parameter}.yaml":
    source => "puppet:///modules/bar/not-yaml.${parameter}",
  }

  file { '/tmp/static/similar-yaml.yaml':
    source => "puppet:///modules/bar/similar-yaml.${parameter}"
  }

  file { '/tmp/static/similar-yaml.json':
    source => "puppet:///modules/bar/similar-yaml.${parameter}"
  }

  file { '/tmp/static/unparseable-yaml.yaml':
    source => 'puppet:///modules/bar/unparseable-yaml.default',
  }

  file { '/tmp/static/unparseable-yaml-2.yaml':
    source => "puppet:///modules/bar/unparseable-yaml.${parameter}",
  }

  file { "/tmp/static/unparseable-yaml-${parameter}.yaml":
    source => "puppet:///modules/bar/unparseable-yaml.${parameter}",
  }
}
