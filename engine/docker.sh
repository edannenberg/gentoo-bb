#!/usr/bin/env bash
#
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#    disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#    following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

DOCKER_IO=$(command -v docker.io)
DOCKER="${DOCKER:-${DOCKER_IO:-docker}}"
DOCKER_BUILD_OPTS="${DOCKER_BUILD_OPTS:-}"
DOCKER_COMMIT_OPTS="${DOCKER_COMMIT_OPTS:-}"

_container_mount_portage='false'
_portage_image_processed='false'

# Is this engine functional? Called once per engine in current image dependency graph.
function validate_engine() {
    local docker_version
    _required_binaries+=" ${DOCKER}"
    has_required_binaries
    docker_version=$(${DOCKER} "version") || die "Failed to query ${DOCKER}:\\n${docker_version}"
}

# Has given image_id all requirements to start the build? Called once per image in current image dependency graph.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_path
function validate_image() {
    local image_id image_path
    image_id="$1"
    image_path="$2"
    # shellcheck disable=SC2154
    file_exists_or_die "${image_path}/Dockerfile.template"
}

# Generate Dockerfile from Dockerfile.template for given absolute image_path.
#
# Arguments:
# 1: image_path
function generate_dockerfile() {
    local image_path sed_param bob_var build_timestamp
    image_path="$1"
    sed_param=()
    [[ ! -f "${image_path}"/Dockerfile.template ]] && die "Couldn't read ${image_path}/Dockerfile.template"
    # make variables starting with BOB_ available in Dockerfile.template
    for bob_var in ${!BOB_*}; do
        sed_param+=(-e "s|\${${bob_var}}|${!bob_var}|")
    done
    build_timestamp=$(date '+%Y%m%d%H%M%S')

    # shellcheck disable=SC2016,SC2153,SC2154
    sed "${sed_param[@]}" \
        -e 's|${IMAGE_PARENT}|'"${IMAGE_PARENT}"'|g' \
        -e 's|${DEFAULT_BUILDER}|'"${DEFAULT_BUILDER}"'|g' \
        -e 's/${NAMESPACE}/'"${_current_namespace}"'/g' \
        -e 's/${TAG}/'"${IMAGE_TAG}"'/g' \
        -e 's/${MAINTAINER}/'"${AUTHOR}"'/g' \
        "${image_path}/Dockerfile.template" > "${image_path}/Dockerfile" \
            || die "Error while generating ${image_path}/Dockerfile"

    # insert build timestamp last to preserve build cache
    echo "LABEL kubler.build.timestamp=${build_timestamp}" >> "${image_path}"/Dockerfile
}

# Returns given tag value from dockerfile or exit signal 3 if tag was not found.
# Returns "true" if TAG was found but has no value.
#
# Arguments:
# 1: tag (i.e. FROM)
# 2: image_path
function get_dockerfile_tag() {
    __get_dockerfile_tag=
    local tag image_path dockerfile grep_out regex
    tag="$1"
    image_path="$2"
    dockerfile="${image_path}/Dockerfile"
    file_exists_or_die "${dockerfile}"
    grep_out="$(grep ^"${tag}" "${dockerfile}")"
    regex="^${tag} ?(.*)?"
    if [[ "${grep_out}" =~ $regex ]]; then
        if [[ -n "${BASH_REMATCH[1]}" ]]; then
            # shellcheck disable=SC2034
            __get_dockerfile_tag="${BASH_REMATCH[1]}"
        else
            exit 3
        fi
    fi
}

# Remove image from local image store
#
# Arguments:
# 1: image_id
# 2: image_tag
# 3: remove_by_id - optional, rm the image via Docker image id which might also remove other tags that ref the same id
function remove_image() {
    local image_id image_tag remove_by_id
    image_id="$1"
    image_tag="${2:-${IMAGE_TAG}}"
    remove_by_id="${3:-false}"

    image_id="${image_id}:${image_tag}"

    if [[ "${remove_by_id}" == 'true' ]]; then
        image_id="$("${DOCKER}" images "${image_id}" -q)"
    fi

    "${DOCKER}" rmi -f "${image_id}" 1> /dev/null || die "Failed to remove image ${image_id}"
}

# Build the image for given image_id
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_path
# 3: image_type - $_IMAGE_PATH or $_BUILDER_PATH, defaults to $_IMAGE_PATH
# 4: skip_rootfs - optional, default: false
function build_image() {
    local image_id image_type image_path skip_rootfs builder_id builder_commit_id current_image bob_var run_id exit_sig
    image_id="$1"
    image_path="$2"
    image_type="${3:-${_IMAGE_PATH}}"
    skip_rootfs="$4"

    # add current image id to output logging
    add_status_value "${image_id}"

    local missing_builder
    missing_builder=
    if [[ "${skip_rootfs}" != 'true' ]]; then
        get_build_container "${image_id}" "${image_type}"
        builder_id="${__get_build_container}"

        # determine build container commit id
        builder_commit_id=""
        current_image="${image_id##*/}"
        if [[ -n "${BUILDER}" ]]; then
            builder_commit_id="${BUILDER##*/}-${current_image}"
        elif [[ "${image_type}" == "${_IMAGE_PATH}" ]]; then
            local builder_image_id image_parent_id
            builder_image_id="${builder_id##*/}"
            image_parent_id="${IMAGE_PARENT##*/}"
            builder_commit_id="${builder_image_id%-${image_parent_id}}-${current_image}"
        fi

        if [[ "${image_type}" == "${_BUILDER_PATH}" ]]; then
            [[ "${builder_id}" == "${image_id}" && "${image_id}" != "${_current_namespace}"/*-core ]] && \
                builder_id="${image_id}-core"
            builder_commit_id="${image_id##*/}"
        fi
        # always rebuild if builder image doesn't exist
        if ! image_exists "${_current_namespace}/${builder_commit_id}"; then
            [[ -f "${image_path}/rootfs.tar" ]] && rm "${image_path}/rootfs.tar"
            missing_builder='true'
        fi

        # shellcheck disable=SC2154
        if [[ "${_arg_force_full_image_build}" == 'off' && -z "${missing_builder}" ]]; then
            local builder_timestamp parent_builder_timestamp

            get_image_label "${_current_namespace}/${builder_commit_id}" "${IMAGE_TAG}" "kubler.build.timestamp"
            builder_timestamp="${__get_image_label}"
            get_image_label "${builder_id}" "${IMAGE_TAG}" "kubler.build.timestamp"
            parent_builder_timestamp="${__get_image_label}"

            if [[ -n "${parent_builder_timestamp}" && "${parent_builder_timestamp}" -gt "${builder_timestamp}" ]]; then
                _status_msg="parent builder more recent, rebuilding."
                pwrap 'nolog' sleep 1
                [[ -f "${image_path}/rootfs.tar" ]] && rm "${image_path}/rootfs.tar"
                missing_builder='true'
            fi
        fi
    fi

    image_exists_or_rm "${image_id}" "${image_type}"
    exit_sig=$?
    if [[ -z "${missing_builder}" && ${exit_sig} -eq 0 ]]; then
        if [[ ! -f "${image_path}/${_BUILD_TEST_FAILED_FILE}" && \
              ! -f "${image_path}/${_HEALTHCHECK_FAILED_FILE}" ]]
        then
            local image_timestamp parent_timestamp

            get_image_label "${image_id}" "${IMAGE_TAG}" "kubler.build.timestamp"
            image_timestamp="${__get_image_label}"
            get_image_label "${IMAGE_PARENT}" "${IMAGE_TAG}" "kubler.build.timestamp"
            parent_timestamp="${__get_image_label}"

            if [[ -z "${parent_timestamp}" || "${parent_timestamp}" -lt "${image_timestamp}" ]]; then
                msg_ok "skipped, already built."
                return 0
            fi

            _status_msg="parent more recent than image, rebuilding."
            pwrap 'nolog' sleep 1
        fi
    fi

    # if the builder image does not exist we need to ensure there is no pre-existing rootfs.tar
    if [[ ${exit_sig} -eq 3 && "${image_type}" == "${_BUILDER_PATH}" ]]; then
        [[ -f "${image_path}/rootfs.tar" ]] && rm "${image_path}/rootfs.tar"
    fi

    generate_dockerfile "${image_path}"

    # build rootfs?
    # shellcheck disable=SC2154
    if [[ ! -f "${image_path}/rootfs.tar" || "${_arg_force_full_image_build}" == 'on' ]] && \
       [[ "${skip_rootfs}" != 'true' ]]; then

        # save value of target image's PARENT_BUILDER_MOUNTS config as get_build_container() may override the ENV
        unset _use_parent_builder_mounts
        # shellcheck disable=SC2034
        [[ "${PARENT_BUILDER_MOUNTS}" == 'true' ]] && _use_parent_builder_mounts='true'

        [[ ! -d "${KUBLER_DISTFILES_DIR}" ]] && mkdir -p "${KUBLER_DISTFILES_DIR}"
        [[ ! -d "${KUBLER_PACKAGES_DIR}" ]] && mkdir -p "${KUBLER_PACKAGES_DIR}"

        _container_mounts=("${image_path}:/config"
                           "${KUBLER_DISTFILES_DIR}:/distfiles"
                           "${KUBLER_PACKAGES_DIR}:/packages"
                          )
        [[ ${#BUILDER_MOUNTS[@]} -gt 0 ]] && _container_mounts+=("${BUILDER_MOUNTS[@]}")

        # shellcheck disable=SC2034
        BOB_CURRENT_TARGET="${image_id}"

        # pass variables starting with BOB_ to build container as ENV
        for bob_var in ${!BOB_*}; do
            _container_env+=("${bob_var}=${!bob_var}")
        done

        _container_args=()
        [[ ${#BUILDER_DOCKER_ARGS_GLOBAL[@]} -gt 0 ]] && _container_args+=("${BUILDER_DOCKER_ARGS_GLOBAL[@]}")
        [[ ${#BUILDER_DOCKER_ARGS[@]} -gt 0 ]] && _container_args+=("${BUILDER_DOCKER_ARGS[@]}")
        _container_cmd=("kubler-build-root")
        _container_mount_portage="true"

        run_id="rootfs-builder-${image_id//\//-}-${$}-${RANDOM}"
        if [[ "${image_type}" == "${_IMAGE_PATH}" ]]; then
            _status_msg="build root-fs using ${builder_id}:${IMAGE_TAG}"
        else
            _status_msg="bootstrap builder environment"
        fi
        pwrap run_image "${builder_id}:${IMAGE_TAG}" "${image_id}" "false" "${run_id}" \
            || die "${_status_msg}"

        _container_mount_portage='false'

        _status_msg="commit ${run_id} as image ${_current_namespace}/${builder_commit_id}:${IMAGE_TAG}"
        # shellcheck disable=SC2086
        pwrap 'nolog' "${DOCKER}" commit ${DOCKER_COMMIT_OPTS} -c "LABEL kubler.build.timestamp=$(date '+%Y%m%d%H%M%S')" \
            "${run_id}" "${_current_namespace}/${builder_commit_id}:${IMAGE_TAG}" \
            || die "${_status_msg}"

        _status_msg="remove container ${run_id}"
        pwrap 'nolog' "${DOCKER}" rm "${run_id}" || die "${_status_msg}"

        _status_msg="tag image ${_current_namespace}/${builder_commit_id}:latest"
        pwrap 'nolog' "${DOCKER}" tag "${_current_namespace}/${builder_commit_id}:${IMAGE_TAG}" \
            "${_current_namespace}/${builder_commit_id}:latest" \
            || { msg_error "${_status_msg}"; die; }
    fi

    _status_msg="exec ${DOCKER} build -t ${image_id}:${IMAGE_TAG}"
    # shellcheck disable=SC2086
    pwrap "${DOCKER}" build ${DOCKER_BUILD_OPTS} -t "${image_id}:${IMAGE_TAG}" "${image_path}" || die "${_status_msg}"

    _status_msg="tag image ${image_id}:latest"
    pwrap 'nolog' "${DOCKER}" tag "${image_id}:${IMAGE_TAG}" "${image_id}:latest" || die "${_status_msg}"

    [[ "${KUBLER_POSTBUILD_IMAGE_PRUNE}" == 'true' ]] \
        && _status_msg="remove untagged images" && pwrap "${DOCKER}" image prune -f

    [[ "${KUBLER_POSTBUILD_VOLUME_PRUNE}" == 'true' ]] \
        && _status_msg="remove unused volumes" && pwrap "${DOCKER}" volume prune -f

    add_documentation_header "${image_id}" "${image_type}" || die "Failed to generate PACKAGES.md for ${image_id}"
    local has_tests done_text
    [[ -n "${POST_BUILD_HC}" || -f "${image_path}/build-test.sh" ]] && has_tests='true'

    # shellcheck disable=SC2154
    msg "${_term_cup}"
    if [[ -n "${has_tests}" ]]; then
        test_image "${image_id}:${IMAGE_TAG}" "${image_path}"
    else
        done_text='done.'
        [[ -z "${has_tests}" && "${image_type}" != "${_BUILDER_PATH}" ]] \
            && done_text="${done_text} no tests. ;("
        msg_ok "${done_text}"
    fi
}

#
# Arguments:
# 1: image_id
# 2: image_path
test_image() {
    local image_id image_path exit_sig container_name failed_test_file
    image_id="${1}"
    image_path="${2}"

    # run build-test.sh in a test container
    if [[ -f "${image_path}"/build-test.sh ]]; then
        failed_test_file="${image_path}/${_BUILD_TEST_FAILED_FILE}"
        container_name="build-test-${image_id//[\:\/]/-}"
        _container_mounts=( "${image_path}:/kubler-test/" )
        _container_args=()
        _container_cmd=( '/kubler-test/build-test.sh' )
        _status_msg="exec build-test.sh in container ${container_name}"
        pwrap run_image "${image_id}" "${image_id}" 'true' "${container_name}" 'false'
        exit_sig=$?
        [[ ${exit_sig} -gt 0 ]] \
            && date > "${failed_test_file}" \
            && die "build-test.sh for image ${image_id} failed with exit signal: ${exit_sig}"
        [[ -f "${failed_test_file}" ]] && rm "${failed_test_file}"
    fi

    # run a detached container and monitor Docker's health-check status
    if [[ -n "${POST_BUILD_HC}" ]]; then
        local hc_current_duration hc_healthy_streak hc_failed_streak hc_itr hc_status hc_log status_tmpl hc_streak_bar
        POST_BUILD_HC_MAX_DURATION="${POST_BUILD_HC_MAX_DURATION:-30}"
        POST_BUILD_HC_INTERVAL="${POST_BUILD_HC_INTERVAL:-5}"
        POST_BUILD_HC_TIMEOUT="${POST_BUILD_HC_TIMEOUT:-5}"
        POST_BUILD_HC_START_PERIOD="${POST_BUILD_HC_START_PERIOD:-3}"
        POST_BUILD_HC_RETRIES="${POST_BUILD_HC_RETRIES:-3}"
        POST_BUILD_HC_MIN_HEALTHY_STREAK="${POST_BUILD_HC_MIN_HEALTHY_STREAK:-5}"

        container_name="health-check-${image_id//[\:\/]/-}"
        _container_mounts=()
        _container_cmd=()
        _container_args=( '-d'
            '--health-interval' "${POST_BUILD_HC_INTERVAL}s"
            '--health-retries' "${POST_BUILD_HC_RETRIES}"
            '--health-start-period' "${POST_BUILD_HC_START_PERIOD}s"
            '--health-timeout' "${POST_BUILD_HC_TIMEOUT}s" )

        # shellcheck disable=SC2064
        _handle_hc_container_run_args="${container_name}"
        add_trap_fn 'handle_hc_container_run'
        _status_msg="monitor health-check of container ${container_name}"
        pwrap run_image "${image_id}" "${image_id}" 'true' "${container_name}"
        _status_msg="health-check startup time is ${POST_BUILD_HC_START_PERIOD}s"
        pwrap 'nolog' sleep "${POST_BUILD_HC_START_PERIOD}"
        hc_current_duration=0
        hc_healthy_streak=0
        hc_failed_streak=0
        hc_itr=0
        repeat_str '-' "${POST_BUILD_HC_MIN_HEALTHY_STREAK}"
        # shellcheck disable=SC2154
        hc_streak_bar="${__repeat_str}"
        hc_status='n/a'
        msg -e ""
        # shellcheck disable=SC2154
        [[ "${_is_terminal}" == 'false' ]] && msg_info "monitor docker health-check\n"

        while [[ ${POST_BUILD_HC_MAX_DURATION} -gt ${hc_current_duration} ]]; do
            if [[ ${hc_itr} -ge ${POST_BUILD_HC_INTERVAL} ]]; then
                hc_status="$("${DOCKER}" inspect "${container_name}" | jq '.[] | .State.Health.Status')"
                hc_log="$("${DOCKER}" inspect "${container_name}" | jq '.[] | .State.Health.Log[4].Output')"
                [[ "${hc_status}" == '"healthy"' ]] && hc_healthy_streak=$((hc_healthy_streak + 1))
                [[ "${hc_status}" == '"unhealthy"' ]] && hc_failed_streak=$((hc_failed_streak + 1))
                repeat_str '*' "${hc_healthy_streak}"
                # shellcheck disable=SC2154
                hc_streak_bar="${_term_green}${__repeat_str}${_term_reset}"
                repeat_str '-' $(( POST_BUILD_HC_MIN_HEALTHY_STREAK - hc_healthy_streak ))
                hc_streak_bar="${hc_streak_bar}${__repeat_str}"
                hc_itr=0
            fi
            status_tmpl="health-check status: "
            # shellcheck disable=SC2154
            status_tmpl="${status_tmpl}${_term_yellow}[${_term_reset}up: %ss${_term_yellow}]-${_term_reset}"
            status_tmpl="${status_tmpl}${_term_yellow}[${_term_reset}next: %ss${_term_yellow}]-${_term_reset}"
            status_tmpl="${status_tmpl}${_term_yellow}[${_term_reset}%s${_term_yellow}]-${_term_reset}"
            status_tmpl="${status_tmpl}${_term_yellow}[${_term_reset}%s${_term_yellow}]${_term_reset}"
            # shellcheck disable=SC2059
            printf -v _status_msg "${status_tmpl}" \
                "${hc_current_duration}" \
                $(( POST_BUILD_HC_INTERVAL - hc_itr )) \
                "${hc_status}" \
                "${hc_streak_bar}"
            [[ "${_is_terminal}" == 'true' ]] && status_with_spinner "${_status_msg}"
            [[ ${hc_healthy_streak} -ge ${POST_BUILD_HC_MIN_HEALTHY_STREAK} ]] && break
            hc_itr=$(( hc_itr + 1 ))
            hc_current_duration=$(( hc_current_duration + 1 ))
            sleep 1
        done
        rm_trap_fn 'handle_hc_container_run'

        stop_container "${container_name}" 'false'
        # shellcheck disable=SC2154
        msg "${_term_cup}${_term_ceol}${_term_cup}"
        failed_test_file="${image_path}/${_HEALTHCHECK_FAILED_FILE}"
        [[ ${hc_healthy_streak} -lt ${POST_BUILD_HC_MIN_HEALTHY_STREAK} ]] \
            && date > "${failed_test_file}" \
            && die "health-check failed: timeout after ${POST_BUILD_HC_MAX_DURATION}s. docker inspect log:\n${hc_log}"
        [[ -f "${failed_test_file}" ]] && rm "${failed_test_file}"
    fi
    # shellcheck disable=SC2154
    msg "${_term_cup}"
    msg_ok "done."
}

function handle_hc_container_run() {
    local container_id
    container_id="${_handle_hc_container_run_args}"
    echo -e ""
    msg_error "aborting.. stopping health-check test container ${container_id}"
    container_exists "${container_id}" && stop_container "${container_id}" 'false'
}

# Check if container exists for given container_name, exit with signal 3 if it does not
#
# Arguments:
# 1: container_name
function container_exists() {
    local container_name
    container_name="$1"
    "${DOCKER}" inspect "${container_name}" > /dev/null 2>&1 || return 3
    return 0
}

# Check if image exists, remove existing image depending on passed build args. (-f, -F, -c, -C)
# Returns signal 0 if image exists, or signal 3 if not or image was removed due to build args.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_type - $_IMAGE_PATH or $_BUILDER_PATH, optional, default: $_IMAGE_PATH
# 3: image_tag - optional, default: $IMAGE_TAG
function image_exists_or_rm() {
    local image_id image_type
    image_id="${1}"
    image_type="${2:-${_IMAGE_PATH}}"
    image_tag="${3:-${IMAGE_TAG}}"
    image_exists "${image_id}" "${image_tag}" || return $?
    # shellcheck disable=SC2154
    if [[ "${_arg_clear_everything}" == 'on' ]] \
        && [[ "${image_id}" != "${_PORTAGE_IMAGE}" || "${KUBLER_PORTAGE_GIT}" != 'true' ]]
    then
        [[ "${image_id}" == "${_PORTAGE_IMAGE}" ]] && stop_container "${_PORTAGE_CONTAINER}"
        # -C
        remove_image "${image_id}" "${image_tag}"
        return 3
    elif [[ "${_arg_clear_build_container}" == 'on' && "${image_type}" == "${_BUILDER_PATH}" ]]; then
        # -c => rebuild builder if not stage3 or portage image
        if [[ "${image_id}" != "${_STAGE3_NAMESPACE}/${STAGE3_BASE//+/-}" && "${image_id}" != "${_PORTAGE_IMAGE}" ]]; then
            remove_image "${image_id}" "${image_tag}"
            return 3
        fi
    elif [[ "${_arg_force_image_build}" == 'on' || "${_arg_force_full_image_build}" == 'on' ]]; then
        # -f, -F => rebuild image if not a builder or portage
        [[ "${image_type}" != "${_BUILDER_PATH}" && "${image_id}" != "${_PORTAGE_IMAGE}" ]] \
            && remove_image "${image_id}" "${image_tag}" && return 3
    fi
    return 0
}

# Check if image exits for given image_id, returns signal 3 if not.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_tag - optional, default: $IMAGE_TAG
function image_exists() {
    local image_id image_type image_tag
    image_id="${1}"
    image_tag="${2:-${IMAGE_TAG}}"
    # image exists?
    "${DOCKER}" inspect "${image_id}:${image_tag}" > /dev/null 2>&1 || return 3
    return 0
}

# Sets __get_image_size for given image_id, required for generating PACKAGES.md header
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_tag (a.k.a. version)
function get_image_size() {
    __get_image_size=
    local image_id image_tag image_size
    image_id="$1"
    image_tag="$2"
    image_size="$(${DOCKER} images "${image_id}:${image_tag}" --format '{{.Size}}')"
    # shellcheck disable=2181
    [[ $? -ne 0 ]] && die "Couldn't determine image size for ${image_id}:${image_tag}: ${image_size}"
    # shellcheck disable=SC2034
    __get_image_size="${image_size}"
}

# Sets __get_image_label for given image_id, image_tag and label_name
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_tag (a.k.a. version)
# 3: label_name (i.e. kubler.build.timestamp)
function get_image_label() {
    __get_image_label=
    local image_id image_tag image_label
    image_id="$1"
    image_tag="$2"
    label_name="$3"
    if [[ "${image_id}" != "scratch" ]]; then
        image_label="$(${DOCKER} inspect --format='{{index .Config.Labels "'"${label_name}"'"}}' "${image_id}":"${image_tag}")"
        # shellcheck disable=SC2034
        __get_image_label="${image_label}"
    fi
}

# Start a container from given image_id.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: container_host_name
# 3: remove container after it exists, optional, default: true
# 4: container_name, optional, keep in mind that this needs to be unique for all existing containers on the host
# 5: exit_on_error, optional, if false will just return the exit signal instead of aborting, default: true
function run_image() {
    local image_id container_host_name auto_rm container_name exit_on_error docker_env denv docker_mounts dmnt
    image_id="$1"
    container_host_name="$2"
    auto_rm="${3:-true}"
    container_name="${4:-${IMAGE_TAG}}"
    container_name="${container_name//[\:\/]/-}"
    exit_on_error="${5:-true}"
    # docker env options
    docker_env=()
    for denv in "${_container_env[@]}"; do
        docker_env+=('-e' "${denv}")
    done
    # docker mount options
    docker_mounts=()
    for dmnt in "${_container_mounts[@]}"; do
        docker_mounts+=('-v' "${dmnt}")
    done
    # general docker args
    docker_args=("-it" "--hostname" "${container_host_name//\//-}")
    [[ "${auto_rm}" == "true" ]] && docker_args+=("--rm")
    [[ -n "${container_name}" ]] && docker_args+=("--name" "${container_name//\//-}")
    [[ "${BUILDER_CAPS_SYS_PTRACE}" == "true" ]] && docker_args+=('--cap-add' 'SYS_PTRACE')
    [[ -n "${BUILDER_SECCOMP}" ]] && docker_args+=("--security-opt" "seccomp=${BUILDER_SECCOMP}")
    [[ "${_container_mount_portage}" == "true" ]] && docker_args+=("--volumes-from" "${_PORTAGE_IMAGE//\//-}")
    # shellcheck disable=SC2154
    [[ ${#_container_args[@]} -gt 0 ]] && docker_args+=("${_container_args[@]}")
    local exit_sig
    # shellcheck disable=SC2064
    _handle_container_run_args="${container_name}"
    add_trap_fn 'handle_container_run'
    "${DOCKER}" run "${docker_args[@]}" "${docker_mounts[@]}" "${docker_env[@]}" "${image_id}" "${_container_cmd[@]}"
    exit_sig=$?
    [[ ${exit_sig} -ne 0 && "${exit_on_error}" == 'true' ]] && die "Failed to run image ${image_id}"
    rm_trap_fn 'handle_container_run'
    return ${exit_sig}
}

# Trap handler for run_image fn.
function handle_container_run() {
    local container_id
    container_id="${_handle_container_run_args}"
    if [[ -z "${NO_CLEANUP}" ]] && container_exists "${container_id}"; then
        msg_error "removing ${container_id}, NO_CLEANUP env prevents this"
        "${DOCKER}" rm "${container_id}" 1> /dev/null
    fi
}

# Arguments:
# 1: container_name - the container to stop
# 2: remove_container - optional, if true also removes the container, default: true
function stop_container() {
    local container_name remove_container exit_sig
    container_name="$1"
    remove_container="${2:-true}"
    "${DOCKER}" stop "${container_name}" 1> /dev/null
    exit_sig=$?
    [[ "${remove_container}" == 'true' ]] && { "${DOCKER}" rm "${container_name}" 1> /dev/null; exit_sig=$?; }
    return "${exit_sig}"
}

# Docker import a portage snapshot as given portage_image_id
#
# Arguments:
# 1: portage_image_id (i.e. bob/portage)
# 2: image_tag (a.k.a. version)
function import_portage_tree() {
    local image_id image_tag image_path portage_file portage_tmp_file
    image_id="$1"
    image_tag="$2"
    image_exists_or_rm "${image_id}" "${image_tag}" && return 0

    # add current image id to output logging
    add_status_value 'portage'

    _status_msg="download portage snapshot"
    PORTAGE_DATE="${PORTAGE_DATE:-latest}"
    portage_file="portage-${PORTAGE_DATE}.tar.xz"
    _pwrap_callback=( 'cb_add_filesize_to_status' "${KUBLER_DOWNLOAD_DIR}/${portage_file//latest/${_TODAY}}" )
    pwrap download_portage_snapshot "${portage_file}" || die "Failed to download portage snapshot ${portage_file}"

    portage_file="${portage_file//latest/${_TODAY}}"

    if [[ "${KUBLER_DISABLE_KUBLER_NS}" != 'true' ]]; then
        image_path="${KUBLER_DATA_DIR}"/namespaces/kubler/builder/bob-portage
    else
        image_path="${KUBLER_DATA_DIR}"/tmp/kubler-portage
    fi
    [[ ! -d "${image_path}" ]] && mkdir -p "${image_path}"
    cp "${_KUBLER_DIR}"/engine/docker/bob-portage/Dockerfile.template "${image_path}"/

    add_trap_fn 'handle_import_portage_tree_error'
    # shellcheck disable=SC2154
    portage_tmp_file="${image_path}/${portage_file}"
    cp "${KUBLER_DOWNLOAD_DIR}/${portage_file}" "${portage_tmp_file}"
    export BOB_CURRENT_PORTAGE_FILE="${portage_file}"

    _status_msg="bootstrap ${image_id} image"
    generate_dockerfile "${image_path}"
    pwrap "${DOCKER}" build -t "${image_id}:${image_tag}" "${image_path}" \
        || die "Failed to build ${image_id}:${image_tag}"
    rm_trap_fn 'handle_import_portage_tree_error'
    rm -r "${image_path}"
    unset PORTAGE_DATE
    _status_msg="tag image ${image_id}:latest"
    pwrap "${DOCKER}" tag "${image_id}:${image_tag}" "${image_id}:latest" \
        || die "Failed to tag ${image_id}:${image_tag}"
    _portage_image_processed='true'
}

function handle_import_portage_tree_error() {
    [[ -d "${KUBLER_DATA_DIR}"/namespaces/kubler/builder/bob-portage ]] \
        && rm -r "${KUBLER_DATA_DIR}"/namespaces/kubler/builder/bob-portage
    [[ -d "${KUBLER_DATA_DIR}"/tmp/kubler-portage ]] && rm -r "${KUBLER_DATA_DIR}"/tmp/kubler-portage
    dir_is_empty "${KUBLER_DATA_DIR}"/tmp && rm -r "${KUBLER_DATA_DIR}"/tmp
}

# Docker import a stage3 tar ball for given stage3_image_id
#
# Arguments:
# 1: stage3_image_id (i.e. bob/${STAGE3_BASE})
function import_stage3() {
    local image_id cat_bin stage3_file
    image_id="${1//+/-}"

    fetch_stage3_archive_name || die "Couldn't find a stage3 file for ${ARCH_URL}"
    # shellcheck disable=SC2154
    stage3_file="${__fetch_stage3_archive_name}"

    # if fetched stage3 archive name doesn't have a matching STAGE3_DATE force the configured one
    get_stage3_archive_regex "${STAGE3_BASE}"
    # shellcheck disable=SC2154,SC2153
    if [[ "${stage3_file}" =~ ${__get_stage3_archive_regex} && "${stage3_file}" != *"${STAGE3_DATE}"* ]]; then
        stage3_file="${STAGE3_BASE}-${STAGE3_DATE}.tar.${BASH_REMATCH[3]}"
    fi

    image_exists_or_rm "${image_id}" "${_BUILDER_PATH}" "${STAGE3_DATE}" && return 0

    _status_msg="download ${stage3_file}"
    # shellcheck disable=SC2034
    _pwrap_callback=( 'cb_add_filesize_to_status' "${KUBLER_DOWNLOAD_DIR}/${stage3_file}" )
    pwrap download_stage3 "${stage3_file}" || die "Failed to download stage3 file"

    _status_msg="import ${stage3_file}"
    pwrap import_tarball "${KUBLER_DOWNLOAD_DIR}/${stage3_file}" "${image_id}:${STAGE3_DATE}" \
        || die "Failed to import ${stage3_file}"

    _status_msg="tag ${image_id}:latest"
    pwrap "${DOCKER}" tag "${image_id}:${STAGE3_DATE}" "${image_id}:latest" || die "Failed to tag ${image_id}:latest"
}

# Create a new Docker image from a file archive.
#
# Arguments:
#
# 1: tarball_path - file to import, xz and bz only
# 2: image_id - docker image id for the new image
function import_tarball() {
    local tarball_path image_id cat_bin
    tarball_path="$1"
    image_id="$2"
    cat_bin='bzcat'
    [[ "${tarball_path##*.}" == 'xz' ]] && cat_bin='xzcat'
    "${cat_bin}" < "${tarball_path}" | bzip2 | "${DOCKER}" import - "${image_id}" \
        || return 1
}

# This function is called once per stage3 build container and should
# bootstrap a stage3 with portage plus helper files from /bob-core.
#
# Arguments:
# 1: builder_id (i.e. kubler/bob)
function build_core() {
    local builder_id core_id image_path
    builder_id="$1"
    core_id="${builder_id}-core"

    # when -C is active this might get called multiple times for a build
    [[ "${_portage_image_processed}" == 'false' ]] && import_portage_tree "${_PORTAGE_IMAGE}" "${PORTAGE_DATE}"

    # ensure the portage container is created
    container_exists "${_PORTAGE_CONTAINER}"
    [[ $? -eq 3 ]] &&
        _status_msg="create the portage container" && \
        pwrap "${DOCKER}" run '--name' "${_PORTAGE_CONTAINER}" "${_PORTAGE_IMAGE}" true

    # add current image id to output logging
    add_status_value "${core_id}"

    BOB_CURRENT_STAGE3_ID="${_STAGE3_NAMESPACE}/${STAGE3_BASE//+/-}"
    import_stage3 "${BOB_CURRENT_STAGE3_ID}"

    image_exists_or_rm "${core_id}" "${_BUILDER_PATH}" && return 0
    expand_image_id "${core_id}" "${_BUILDER_PATH}"
    # shellcheck disable=SC2154
    image_path="${__expand_image_id}"
    [[ ! -d "${image_path}" ]] && { mkdir -p "${image_path}" || die; }

    _handle_build_core_error_args="${image_path}"
    add_trap_fn 'handle_build_core_error'
    # copy build-root.sh and emerge defaults so we can access it via dockerfile context
    cp -r "${_KUBLER_DIR}"/engine/docker/bob-core/{*.sh,etc,Dockerfile.template} "${image_path}/" \
        || die "Could not create temporary image at ${image_path}"

    generate_dockerfile "${image_path}"
    build_image "${core_id}" "${image_path}" "${_BUILDER_PATH}" 'true'

    rm_trap_fn 'handle_build_core_error'
    # clean up
    rm -r "${image_path}"

}

function handle_build_core_error() {
    local image_path
    image_path="${_handle_build_core_error_args}"
    [[ -d "${image_path}" ]] && rm -r "${image_path}"
}

# Produces a build container image for given builder_id
# Implement this if you want support for multiple build containers.
#
# Arguments:
# 1: builder_id (i.e. kubler/bob)
# 2: image_path
function build_builder() {
    local builder_id image_path
    builder_id="$1"
    image_path="$2"
    # bootstrap a stage3 image if defined in build.conf
    [[ -n "${STAGE3_BASE}" ]] && build_core "${builder_id}"
    build_image "${builder_id}" "${image_path}" "${_BUILDER_PATH}"
}

# Called when using --no-deps, in most cases a thin wrapper to build_image()
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_path
function build_image_no_deps() {
    local image_id image_path
    image_id="$1"
    image_path="$2"
    build_image "${image_id}" "${image_path}"
}

# Sets __get_build_container to the builder_id required for building given image_id or signal 3 if not found/implemented.
#
# Arguments:
# 1: image_id
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH), default: $_IMAGE_PATH
function get_build_container() {
    __get_build_container=
    local image_id image_type build_container parent_image parent_ns current_image builder_image
    image_id="${1}"
    image_type="${2:-${_IMAGE_PATH}}"
    if [[ "${image_type}" == "${_IMAGE_PATH}" ]]; then
        get_image_builder_id "${image_id}"
        # shellcheck disable=SC2154
        [[ -z "${__get_image_builder_id}" ]] && die "Couldn't find build container for image ${image_id}"
        build_container="${__get_image_builder_id}"
        expand_image_id "${image_id}" "${image_type}"
        # shellcheck disable=SC2154
        source_image_conf "${__expand_image_id}"
    fi

    if [[ -n "${BUILDER}" ]]; then
        # BUILDER was set for this image, override default and start with given base builder from this image on
        build_container="${BUILDER}"
    elif [[ "${image_type}" == "${_IMAGE_PATH}" ]]; then
        # get parent image basename
        parent_image="${IMAGE_PARENT##*/}"
        parent_ns="${IMAGE_PARENT%%/*}"
        builder_image="${build_container##*/}"
        [[ "${parent_image}" != "scratch" ]] && image_exists "${parent_ns}/${builder_image}-${parent_image}" \
            && build_container="${parent_ns}/${builder_image}-${parent_image}"
    elif [[ "${image_type}" == "${_BUILDER_PATH}" ]]; then
        build_container="${image_id}-core"
    fi

    __get_build_container="${build_container}"
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
    add_status_value 'auth'
    if [[ -z "${repository_url}" ]]; then
        DOCKER_LOGIN="${DOCKER_LOGIN:-${namespace}}"
        msg_info "using docker.io/u/${DOCKER_LOGIN}"
        login_args=('-u' "${DOCKER_LOGIN}")
        # shellcheck disable=SC2153
        if [[ -n "${DOCKER_PW}" ]]; then
            login_args+=( '--password-stdin' )
            echo "${DOCKER_PW}" | "${DOCKER}" login "${login_args[@]}" || exit 1
        else
            "${DOCKER}" login "${login_args[@]}" || exit 1
        fi
    else
        msg_info "using ${repository_url}"
    fi
}

# Push image to a repository
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: repository_url
function push_image() {
    local image_id repository_url push_id docker_image_id pid
    image_id="$1"
    repository_url="$2"
    push_id="${image_id}"
    if [[ -n "${repository_url}" ]]; then
        docker_image_id="$("${DOCKER}" images "${image_id}:${IMAGE_TAG}" --format '{{.ID}}')"
        # shellcheck disable=SC2181
        [[ $? -ne 0 ]] && die "Couldn't determine image id for ${image_id}:${IMAGE_TAG}: ${docker_image_id}"
        push_id="${repository_url}/${image_id}"
        for pid in "${push_id}:${IMAGE_TAG}" "${push_id}:latest"; do
            _status_msg="${DOCKER} tag ${docker_image_id} ${pid}"
            pwrap "${DOCKER}" tag "${docker_image_id}" "${pid}" || die
        done
    fi
    add_status_value "${push_id}"
    _status_msg="upload image"
    for pid in "${push_id}:${IMAGE_TAG}" "${push_id}:latest"; do
      pwrap "${DOCKER}" push "${pid}" || die
    done
    msg_ok "done."
}
