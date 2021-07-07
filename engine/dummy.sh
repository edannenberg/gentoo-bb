#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

# A bare bone implementation of the kubler build "interface" that can be used as a template for new engines.
# You can also extend an existing engine and just override a few functions as needed, i.e.:
#source "${_LIB_DIR}/engine/docker.sh"

###
### REQUIRED FUNCTIONS
###

# Is this engine functional? Called once per engine in current image dependency graph.
function validate_engine() {
    #_required_binaries+=" some-command some-other-command"
    #has_required_binaries
    msg "validate dummy engine"
}

# Has given image_id all requirements to start the build? Called once per image in current image dependency graph.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
function validate_image() {
    local image_id image_type
    image_id="$1"
    image_type="$2"
    expand_image_id "${image_id}" "${image_type}"
    #file_exists_or_die "${__expand_image_id}/foo.conf"
    msg "validate dummy repo: ${__expand_image_id}"
}

# Build the image for given image_id
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
function build_image() {
    local image_id image_type
    image_id="${1}"
    image_type="${2:-${_IMAGE_PATH}}"
    msg "building dummy image: ${image_id}"
    # finish PACKAGES.md when using build-root.sh once the build is done:
    #add_documentation_header "${image_id}" "${_IMAGE_PATH}" || die "Failed to generate PACKAGES.md for ${image_id}"
}

# Exits with signal 0 if given image_id has a built and ready to run image or signal 3 if not.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_tag - optional, default: ${IMAGE_TAG}
function image_exists() {
    local image_id image_type image_tag
    image_id="$1"
    image_tag="${2:-${IMAGE_TAG}}"
    return 3
}

# Sets __get_image_size for given image_id, required for generating PACKAGES.md header
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_tag (a.k.a. version)
function get_image_size() {
    # assume failure
    __get_image_size=
    local image_id image_tag
    image_id="$1"
    image_tag="$2"
    # determine image size
    __get_image_size="xxMB"
}

# Start a container from given image_id.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: container_host_name
# 3: remove container after it exists, optional, default: true
# 4: container_name, optional, keep in mind that this needs to be unique for all existing containers on the host
function run_image() {
    local image_id container_host_name auto_rm container_name
    image_id="$1"
    container_host_name="$2"
    auto_rm="${3:-true}"
    container_name="$4"
    msg "running dummy image: ${image_id} with"
    msg " mounts: ${_container_mounts[*]}"
    msg " env: ${container_env[*]}"
    msg " cmd: ${container_cmd[*]}"
}


###
### OPTIONAL (to implement that is, deleting any stubs is asking for trouble)
###


# This function is called once per stage3 build container and should
# bootstrap a stage3 with portage plus helper files from /bob-core.
#
# Arguments:
# 1: builder_id (i.e. kubler/bob)
function build_core() {
    local builder_id
    builder_id="$1"
    #download_portage_snapshot
    #download_stage3
    msg "building dummy core"
}

# Produces a build container image for given builder_id
# Implement this if you want support for multiple build containers.
#
# Arguments:
# 1: builder_id (i.e. kubler/bob)
function build_builder() {
    local builder_id
    builder_id="$1"
    msg "building dummy builder: ${DEFAULT_BUILDER}"
}

# Called when using --no-deps, in most cases a thin wrapper to build_image()
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
function build_image_no_deps() {
    local image_id
    image_id="$1"
    # build the image
    build_image "${image_id}"
}

# Sets __get_build_container to the builder_id required for building given image_id or signal 3 if not found/implemented.
#
# Arguments:
# 1: image_id
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
function get_build_container() {
    # assume failure
    __get_build_container=
    local image_id image_type
    image_id="${1}"
    image_type="${2:-${_IMAGE_PATH}}"
    #__get_build_container="kubler/bob"
    exit 3
}

# Handle image repository auth, called once per namespace if pushing
#
# Arguments:
# 1: namespace (i.e. kubler)
# 2: repository_url
function push_auth() {
    local namespace repository_url login_args
    namespace="$1"
    repository_url="$2"
    msg "logging into dummy repository"
}

# Push image to a repository
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: repository_url
function push_image() {
    local image_id repository_url
    image_id="$1"
    repository_url="$2"
    msg "pushing ${image_id} to dummy repository at ${repository_url}"
}
