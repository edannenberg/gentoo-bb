#!/usr/bin/env bats

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'
load '/usr/lib/bats-file/load.bash'

TEST_DIR="/var/tmp/kubler_tests"

@test "docker_sanity" {
    run docker ps
    assert_success
}

@test "new_namespace" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    
    run ./bin/kubler --working-dir "${TEST_DIR}" new namespace mytest << 'END'


Max
max@example.com

END
    assert_success
    assert_file_exist "${TEST_DIR}/mytest/kubler.conf"
    
    sed -i 's\#MIRROR="http://distfiles.gentoo.org/"\MIRROR="https://gentoo.osuosl.org/"\g' "${TEST_DIR}/mytest/kubler.conf"
}

@test "update" {
    run ./bin/kubler --working-dir "${TEST_DIR}/mytest" update
    assert_success
}

@test "new_image" {
    run ./bin/kubler --working-dir "${TEST_DIR}/mytest" new image mytest/figlet << 'END'
kubler/bash
bt
END
    assert_success
    
    assert_file_exist "${TEST_DIR}/mytest/images/figlet/build-test.sh"
    assert_file_exist "${TEST_DIR}/mytest/images/figlet/build.conf"
    assert_file_exist "${TEST_DIR}/mytest/images/figlet/build.sh"
    
    sed -i 's%_packages=""%_packages="app-misc/figlet"%g' "${TEST_DIR}/mytest/images/figlet/build.sh"
    sed -i 's%false || exit 1%figlet -v | grep -A 2 FIGlet || exit 1%g' "${TEST_DIR}/mytest/images/figlet/build-test.sh"
}

@test "build_image" {
    run unbuffer -p ./bin/kubler --working-dir ${TEST_DIR}/mytest build mytest/figlet -F
    assert_success
}
