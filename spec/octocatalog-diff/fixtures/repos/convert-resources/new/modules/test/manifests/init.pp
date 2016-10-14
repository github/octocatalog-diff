class test {
  file { '/tmp/foo1':
    source => 'puppet:///modules/test/foo-new',
  }

  file { '/tmp/foo2':
    source => 'puppet:///modules/test/foo-old',
  }

  file { '/tmp/foo3':
    source => 'puppet:///modules/test/foo-old2',
  }

  file { '/tmp/binary1':
    source => 'puppet:///modules/test/binary-new',
  }

  file { '/tmp/binary2':
    source => 'puppet:///modules/test/binary-old',
  }

  file { '/tmp/binary3':
    source => 'puppet:///modules/test/binary-old2',
  }

  file { '/tmp/bar':
    content => "content of bar\n",
  }

  file { '/tmp/bar2':
    content => "content of new-bar\n",
  }
}
