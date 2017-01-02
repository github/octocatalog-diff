class test::alias_targets {
  exec { 'the before alias target':
    command => '/bin/true',
    alias   => 'before alias target',
  }

  exec { 'the notify alias target':
    command => '/bin/true',
    alias   => 'notify alias target',
  }

  exec { 'the require alias target':
    command => '/bin/true',
    alias   => 'require alias target',
  }

  exec { 'the subscribe alias target':
    command => '/bin/true',
    alias   => 'subscribe alias target',
  }
}
