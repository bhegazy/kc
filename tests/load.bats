#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

function setup() {
  KC_LIB="$BATS_TEST_DIRNAME/../kc-init.sh"
  stub aws-vault
}

@test "kc-init can be loaded into bash" {
  source $KC_LIB
}

@test "kc-init can be loaded into zsh" {
  zsh -c "source $KC_LIB"
}
