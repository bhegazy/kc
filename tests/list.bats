#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

function setup() {
  KC_LIB="$BATS_TEST_DIRNAME/../kc-init.sh"

  stub aws-vault
  stub kubectl \
    "config get-contexts -o=name : echo -e 'some-context\nanother-context'"

  source $KC_LIB
}

function teardown() {
  unstub aws-vault
  unstub kubectl
}

@test "kc prints contexts when run with no arguments" {
  run kc
  assert_output <<EOT
Possible contexts are:
another-context
some-context
EOT
}
