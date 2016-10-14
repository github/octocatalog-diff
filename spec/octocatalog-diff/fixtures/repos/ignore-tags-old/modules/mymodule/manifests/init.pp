class mymodule {

  mymodule::resource1 { 'one':
    foo => 'FOO-OLD',
    bar => 'BAR-OLD',
  }

  mymodule::resource1 { 'two':
    foo => 'FOO-OLD',
  }

  mymodule::resource1 { 'three':
    bar => 'BAR-OLD',
  }

  mymodule::resource1 { 'four':
  }

  mymodule::resource2 { 'one':
    foo => 'FOO-OLD',
    bar => 'BAR-OLD',
  }

  mymodule::resource2 { 'two':
    foo => 'FOO-OLD',
  }

  mymodule::resource2 { 'three':
    bar => 'BAR-OLD',
  }

  mymodule::resource2 { 'four':
  }

  mymodule::resource2 { 'five':
    foo => 'FOO-OLD',
    bar => 'BAR-OLD',
    tag => ['ignored_catalog_diff'],
  }
}
