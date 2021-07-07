#!/usr/bin/env bats

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'
load '/usr/lib/bats-file/load.bash'

TEST_DIR="/var/tmp/kubler_tests"

@test "depgraph_linear" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cp -a "tests/fixtures/namespaces/depgraph_linear" "${TEST_DIR}/"

    run ./bin/kubler --working-dir "${TEST_DIR}/depgraph_linear" dep-graph --as-raw-dot depgraph_linear
    
    assert_success
    assert_output -p '"scratch" -> "depgraph_linear/a" [label="kubler/bob"];'
    assert_output -p '"depgraph_linear/a" -> "depgraph_linear/b";'
    assert_output -p '"depgraph_linear/b" -> "depgraph_linear/c";'
    
    run ./bin/kubler --working-dir "${TEST_DIR}/depgraph_linear" dep-graph --as-raw-dot depgraph_linear/c
    
    assert_success
    assert_output -p '"scratch" -> "depgraph_linear/a" [label="kubler/bob"];'
    assert_output -p '"depgraph_linear/a" -> "depgraph_linear/b";'
    assert_output -p '"depgraph_linear/b" -> "depgraph_linear/c";'
}

@test "depgraph_circular" {
    rm -rf "${TEST_DIR}"
    mkdir -p "${TEST_DIR}"
    cp -a "tests/fixtures/namespaces/depgraph_circular" "${TEST_DIR}/"

    run timeout -k 5s 5s ./bin/kubler --working-dir "${TEST_DIR}/depgraph_circular" dep-graph --as-raw-dot depgraph_circular
    
    assert_success
    assert_output -p '"depgraph_circular/a" -> "depgraph_circular/b";'
    assert_output -p '"depgraph_circular/b" -> "depgraph_circular/c";'
    assert_output -p '"depgraph_circular/c" -> "depgraph_circular/a";'

    run timeout -k 5s 5s ./bin/kubler --working-dir "${TEST_DIR}/depgraph_circular" dep-graph --as-raw-dot depgraph_circular/c
    
    assert_success
    assert_output -p '"depgraph_circular/a" -> "depgraph_circular/b";'
    assert_output -p '"depgraph_circular/b" -> "depgraph_circular/c";'
    assert_output -p '"depgraph_circular/c" -> "depgraph_circular/a";'
}
