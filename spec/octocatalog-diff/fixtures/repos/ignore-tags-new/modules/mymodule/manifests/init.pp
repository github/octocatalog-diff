class mymodule {

  mymodule::resource1 { 'one':
    foo => 'FOO-NEW',
    bar => 'BAR-NEW',
  }

  mymodule::resource1 { 'two':
    foo => 'FOO-NEW',
  }

  mymodule::resource1 { 'three':
    bar => 'BAR-NEW',
  }

  mymodule::resource1 { 'four':
  }

  mymodule::resource2 { 'one':
    foo => 'FOO-NEW',
    bar => 'BAR-NEW',
  }

  mymodule::resource2 { 'two':
    foo => 'FOO-NEW',
  }

  mymodule::resource2 { 'three':
    bar => 'BAR-NEW',
  }

  mymodule::resource2 { 'four':
  }

  mymodule::resource2 { 'five':
    foo => 'FOO-NEW',
    bar => 'BAR-NEW',
    tag => ['ignored_catalog_diff'],
  }
}
