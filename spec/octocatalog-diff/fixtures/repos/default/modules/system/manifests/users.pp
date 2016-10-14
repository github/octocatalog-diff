class system::users (
  $user_hash,
) {
  ensure_resources('system::user', $user_hash)
}
