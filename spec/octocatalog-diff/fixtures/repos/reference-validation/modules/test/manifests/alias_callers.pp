class test::alias_callers {
  exec { 'before alias caller':
    command => '/bin/true',
    before  => Exec['before alias target'],
  }

  exec { 'notify alias caller':
    command => '/bin/true',
    before  => Exec['notify alias target'],
  }

  exec { 'require alias caller':
    command => '/bin/true',
    before  => Exec['require alias target'],
  }

  exec { 'subscribe alias caller':
    command => '/bin/true',
    before  => Exec['subscribe alias target'],
  }
}
