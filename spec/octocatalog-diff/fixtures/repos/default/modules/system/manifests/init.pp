class system (
  $value_from_hiera_required,
  $value_from_hiera_optional = 'unspecified',
  $value_from_hiera_undef    = undef,
) {
  include system::root_ssh_keys
  include system::users
}
