node default {
  if $::test_class {
    include "test::${::test_class}"
  } else {
    include test
  }
}
