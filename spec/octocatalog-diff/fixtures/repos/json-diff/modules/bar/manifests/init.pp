class bar ( $parameter ) {
  file { '/tmp/template/different-json.json':
    content => template('bar/different-json.erb')
  }

  file { "/tmp/template/different-json-${parameter}.json":
    content => template('bar/different-json.erb')
  }

  file { '/tmp/template/identical-json.json':
    content => template('bar/identical-json.erb')
  }

  file { '/tmp/template/not-json.json':
    content => '{ "title": "This is not YAML" }'
  }

  file { '/tmp/template/not-json-2.json':
    content => template('bar/not-json.erb')
  }

  file { "/tmp/template/not-json-${parameter}.json":
    content => template('bar/not-json.erb')
  }

  file { '/tmp/template/similar-json.yaml':
    content => template('bar/similar-json.erb')
  }

  file { '/tmp/template/similar-json.json':
    content => template('bar/similar-json.erb')
  }

  file { '/tmp/static/different-json.json':
    source => "puppet:///modules/bar/different-json.${parameter}"
  }

  file { "/tmp/static/different-json-${parameter}.json":
    source => "puppet:///modules/bar/different-json.${parameter}"
  }

  file { '/tmp/static/identical-json.json':
    source => 'puppet:///modules/bar/identical-json',
  }

  file { '/tmp/static/not-json.json':
    source => 'puppet:///modules/bar/not-json.default',
  }

  file { '/tmp/static/not-json-2.json':
    source => "puppet:///modules/bar/not-json.${parameter}",
  }

  file { "/tmp/static/not-json-${parameter}.json":
    source => "puppet:///modules/bar/not-json.${parameter}",
  }

  file { '/tmp/static/similar-json.yaml':
    source => "puppet:///modules/bar/similar-json.${parameter}.json"
  }

  file { '/tmp/static/similar-json.json':
    source => "puppet:///modules/bar/similar-json.${parameter}.json"
  }
}
