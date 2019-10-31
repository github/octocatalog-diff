# https://github.com/github/octocatalog-diff/issues/205

class notify_with_hash {
  $foo = [{ bar =>  "baz" }]
  notice($foo[0])
}
