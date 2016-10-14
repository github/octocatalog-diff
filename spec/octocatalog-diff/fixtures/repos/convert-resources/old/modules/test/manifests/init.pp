class test {
  file { '/tmp/foo1':
    source => 'puppet:///modules/test/foo-old',
  }

  file { '/tmp/foo2':
    source => 'puppet:///modules/test/foo-old',
  }

  file { '/tmp/foo3':
    source => 'puppet:///modules/test/foo-old',
  }

  file { '/tmp/binary1':
    source => 'puppet:///modules/test/binary-old',
  }

  file { '/tmp/binary2':
    source => 'puppet:///modules/test/binary-old',
  }

  file { '/tmp/binary3':
    source => 'puppet:///modules/test/binary-old',
  }

  file { '/tmp/bar':
    source => 'puppet:///modules/test/bar-old',
  }

  file { '/tmp/bar2':
    source => 'puppet:///modules/test/bar-old',
  }
}
