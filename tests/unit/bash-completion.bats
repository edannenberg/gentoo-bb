#!/usr/bin/env bats

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'

TEST_DIR="/var/tmp/kubler_tests"

function setup() {
    KUBLER_TEST_BIN=$(realpath ./bin/kubler)
    KUBLER_TEST_LIB=$(realpath ./lib/kubler-completion.bash)
    pushd /var/tmp >/dev/null
    source ${KUBLER_TEST_LIB}
    popd >/dev/null
}

function teardown() {
    :
}

function run_kubler() {
    _kubler || return 1
    printf '%s\n' "${COMPREPLY[@]}" | sort
}

@test "empty_folder" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cd "${TEST_DIR}"

    export COMP_WORDS=("kubler")
    export COMP_CWORD=1
        
    run run_kubler
    
    assert_success
    assert_output "new"
}

@test "empty_folder_new" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cd "${TEST_DIR}"

    export COMP_WORDS=("kubler" "new")
    export COMP_CWORD=2
        
    run run_kubler
    
    assert_success
    assert_output "namespace"
}

@test "empty_namespace" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cp -a "tests/fixtures/namespaces/empty" "${TEST_DIR}/"
    cd "${TEST_DIR}/empty"
    
    export COMP_WORDS=("kubler")
    export COMP_CWORD=1
        
    run run_kubler
    
    assert_success
    assert_line --index 0 "build"
    assert_line --index 1 "clean"
    assert_line --index 2 "dep-graph"
    assert_line --index 3 "new"
    assert_line --index 4 "push"
    assert_line --index 5 "update"
}

@test "empty_namespace_new" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cp -a "tests/fixtures/namespaces/empty" "${TEST_DIR}/"
    cd "${TEST_DIR}/empty"
    
    export COMP_WORDS=("kubler" "new")
    export COMP_CWORD=2
        
    run run_kubler
    
    assert_success
    assert_line --index 0 "builder"
    assert_line --index 1 "image"
}

@test "build_options" {
rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cp -a "tests/fixtures/namespaces/empty" "${TEST_DIR}/"
    cd "${TEST_DIR}/empty"

    export COMP_WORDS=("kubler" "build" "--")
    export COMP_CWORD=2
        
    run run_kubler
    
    assert_success
    assert_line --index 0 "--clear-build-container"
    assert_line --index 1 "--clear-everything"
    assert_line --index 2 "--exclude"
    assert_line --index 3 "--force-full-image-build"
    assert_line --index 4 "--force-image-build"
    assert_line --index 5 "--help"
    assert_line --index 6 "--interactive"
    assert_line --index 7 "--interactive-no-deps"
    assert_line --index 8 "--no-deps"
    assert_line --index 9 "--skip-gpg-check"
    assert_line --index 10 "--verbose-build"
    assert_line --index 11 "--working-dir"
}
