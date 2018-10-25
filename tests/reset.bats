#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

function setup() {
  KC_LIB="$BATS_TEST_DIRNAME/../kc-init.sh"

  stub aws-vault
  stub kubectl

  source $KC_LIB
}

@test "kc prints contexts when run with no arguments" {
  run kc
  assert_line "Possible contexts are:"
}
