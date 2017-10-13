class test (
  String $param_from_nodes   = 'hard-coded',
  String $param_from_special = 'hard-coded',
  String $param_from_common  = 'hard-coded'
) {
  file { '/tmp/nodes': content => $param_from_nodes }
  file { '/tmp/special': content => $param_from_special }
  file { '/tmp/common': content => $param_from_common }
}
