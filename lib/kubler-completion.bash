#!/usr/bin/env bash

# Check if current compwords is in passed word list
# Arguments:
# 1: words_to_check
function _bc_kubler_find_in_compwords() {
    ___bc_kubler_find_in_compwords=
    local word subcommand c
    c=1
    while [[ $c -lt ${COMP_CWORD} ]]; do
        word="${COMP_WORDS[c]}"
        for subcommand in $1; do
            if [[ "${subcommand}" == "${word}" ]]; then
                ___bc_kubler_find_in_compwords="${subcommand}"
                return
            fi
        done
        ((c++))
    done
}

# Scan compwords for --working-dir arg and return it's given path if set
function _bc_kubler_scan_wdir_in_compwords() {
    ___bc_kubler_scan_wdir_in_compwords=
    local word c path_index passed_wdir
    c=1
    path_index=0
    while [[ $c -lt ${COMP_CWORD} ]]; do
        word="${COMP_WORDS[c]}"
        if [[ '--working-dir' == "${word}" ]]; then
            path_index=$(( c + 1 ))
            if [[ ${path_index} -lt ${COMP_CWORD} ]]; then
                passed_wdir="${COMP_WORDS[${path_index}]}"
                [[ -n "${passed_wdir}" ]] && ___bc_kubler_scan_wdir_in_compwords="${COMP_WORDS[${path_index}]}"
            fi
            return
        fi
        ((c++))
    done
}

# Returns an array with all matches for given $pattern and $text.
# Adapted from: http://regexraptor.net/downloads/return_all_matches.sh
#
# Arguments:
# 1: pattern
# 2: text
function _bc_kubler_match_all() {
    ___bc_kubler_match_all=
    local pattern text text_step r_match loop_max regex_computed
    pattern="$1"
    text="$2"

    text_step="${text}"
    r_match[0]=""
    i=0
    loop_max="${#text}"
    for (( ; ; )); do
        [[ "${text_step}" =~ $pattern ]] || true
        regex_computed="${BASH_REMATCH[0]}"
        [[ "${#BASH_REMATCH[*]}" -eq 0 ]] && break
        r_match[i]="${BASH_REMATCH[1]}"
        text_step="${text_step#*$regex_computed}"
        i=$(( i+1 ))
        [[ ${i} -gt ${loop_max} ]] && break
    done
    ___bc_kubler_match_all=("${r_match[@]}")
}

# Init global vars $_bc_kubler_cmds and $_bc_kubler_<cmd>_opts by parsing kubler's help output
function _bc_kubler_init()
{
    local regex_cmds help_output command cmd_opts
    _bc_kubler_init_ns_vars
    regex_cmds=',(--[a-z0-9-]*):'
    for command in "${_bc_kubler_cmds[@]}"; do
        help_output="$(KUBLER_BC_HELP=false ${KUBLER_TEST_BIN:-kubler} "${command}" --help)"
        _bc_kubler_match_all "${regex_cmds}" "${help_output}"
        cmd_opts="${___bc_kubler_match_all[*]}"
        declare -g _bc_kubler_cmd_"${command//-/_}"_opts="${cmd_opts}"
    done
}

# Init namespace related global vars that need to be refreshed on each new completion
function _bc_kubler_init_ns_vars() {
    local help_output parsed_help help_args
    _bc_kubler_dir=
    _bc_kubler_working_dir=
    _bc_kubler_ns_type=
    help_args=()
    _bc_kubler_scan_wdir_in_compwords
    [[ -n "${___bc_kubler_scan_wdir_in_compwords}" ]] \
        && help_args+=( '--working-dir' "${___bc_kubler_scan_wdir_in_compwords}" )
    help_output="$(KUBLER_BC_HELP=true ${KUBLER_TEST_BIN:-kubler} "${help_args[@]}" --help)"
    readarray -t parsed_help <<< "${help_output}"
    _bc_kubler_dir="${parsed_help[0]}"
    _bc_kubler_working_dir="${parsed_help[1]}"
    _bc_kubler_ns_type="${parsed_help[2]}"
    _bc_kubler_ns_default="${parsed_help[3]}"
    IFS=' ' read -r -a _bc_kubler_cmds <<< "${parsed_help[4]}"
}

# complete a kubler namespace
function _bc_kubler_comp_namespace() {
    if [[ "${_bc_kubler_ns_type}" == 'single' ]]; then
        ___bc_kubler_comp_namespace="$(basename -- "${_bc_kubler_working_dir}")/ $(find "${_bc_kubler_dir}/namespaces" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%f/\n')"
    else
        ___bc_kubler_comp_namespace="$(find "${_bc_kubler_working_dir}" "${_bc_kubler_dir}/namespaces" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%f/\n')"
    fi
}

# complete a kubler image id
function _bc_kubler_comp_image() {
    local namespace current_image_path
    namespace="${COMP_WORDS[COMP_CWORD]%/*}"
    if [[ "${namespace}" == 'kubler' ]]; then
        current_image_path="${_bc_kubler_dir}/namespaces/${namespace}/images"
    else
        if [[ "${_bc_kubler_ns_type}" == 'single' && "${namespace}" == "${_bc_kubler_ns_default}" ]]; then
            current_image_path="${_bc_kubler_working_dir}/images"
        else
            if [[ -d "${_bc_kubler_working_dir}/${namespace}/images" ]]; then
                current_image_path="${_bc_kubler_working_dir}/${namespace}/images"
            else
                current_image_path="${_bc_kubler_dir}/namespaces/${namespace}/images"
            fi
        fi
    fi
    ___bc_kubler_comp_image="$(find "${current_image_path}" -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%f ')"
}

function _compopt_nospace() {
    [[ -z "${KUBLER_TEST_BIN}" ]] && compopt -o nospace
    return 0
}

function _kubler() {
    local cur prev kubler_global_opts kubler_cmds current_opts regex_cmds regex_opts current_cmd cmd_opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    kubler_global_opts="--help --debug --working-dir --verbose"

    _bc_kubler_init_ns_vars

    if [[ "${prev}" == '--working-dir' ]]; then
        if declare -f _filedir 1> /dev/null; then
            _filedir -d
        else
            readarray -t COMPREPLY < <(compgen -o dirnames -- "${cur}")
        fi
        return
    fi

    # check for a completed kubler command
    _bc_kubler_find_in_compwords "${_bc_kubler_cmds[*]}"
    if [[ -z "${___bc_kubler_find_in_compwords}" ]]; then
        case "${cur}" in
            # complete global args
            --*)    readarray -t COMPREPLY < <(compgen -W "${kubler_global_opts}" -- "${cur}")
                    ;;
            # complete commands
            *)      if [[ "${_bc_kubler_ns_type}" == 'none' ]];then
                        # only new command allowed if we are not in a kubler ns dir
                        readarray -t COMPREPLY < <(compgen -W "new" -- "${cur}")
                    else
                        readarray -t COMPREPLY < <(compgen -W "${_bc_kubler_cmds[*]}" -- "${cur}")
                    fi
                    ;;
        esac
        return
    else
        # handle various cases for completed commands/args
        current_cmd="${___bc_kubler_find_in_compwords}"
        case "${current_cmd}:${cur}" in
            *:--*)  current_opts="_bc_kubler_cmd_${current_cmd//-/_}_opts";
                    readarray -t COMPREPLY < <(compgen -W "${!current_opts}" -- "${cur}")
                ;;
            build:*/*)  _bc_kubler_comp_image
                        cur="${cur#*/}"
                        readarray -t COMPREPLY < <(compgen -P "${COMP_WORDS[COMP_CWORD]%/*}/" -W "${___bc_kubler_comp_image}" -- "${cur}")
                ;;
            clean:*)  [[ "${prev}" == '-i' || "${prev}" == '--image-ns' ]] && \
                            _bc_kubler_comp_namespace && _compopt_nospace && readarray -t COMPREPLY < <(compgen -W "${___bc_kubler_comp_namespace}" -- "${cur}")
                ;;
            push:*/*)  _bc_kubler_comp_image
                        cur="${cur#*/}"
                        readarray -t COMPREPLY < <(compgen -P "${COMP_WORDS[COMP_CWORD]%/*}/" -W "${___bc_kubler_comp_image}" -- "${cur}")
                ;;
            dep-graph:*/*)
                _bc_kubler_comp_image
                cur="${cur#*/}"
                readarray -t COMPREPLY < <(compgen -P "${COMP_WORDS[COMP_CWORD]%/*}/" -W "${___bc_kubler_comp_image}" -- "${cur}")
                ;;
            new:*)  cmd_opts='builder image namespace'
                    [[ "${_bc_kubler_ns_type}" == 'none' ]] && cmd_opts='namespace'
                    [[ "${_bc_kubler_ns_type}" == 'single' ]] && cmd_opts='builder image'
                    if [[ "${prev}" == 'image' || "${prev}" == 'builder' ]]; then
                        _bc_kubler_comp_namespace && _compopt_nospace && readarray -t COMPREPLY < <(compgen -W "${___bc_kubler_comp_namespace}" -- "${cur}")
                    else
                        _bc_kubler_find_in_compwords "${cmd_opts}"
                        [[ -z "${___bc_kubler_find_in_compwords}" ]] && readarray -t COMPREPLY < <(compgen -W "${cmd_opts}" -- "${cur}")
                    fi
                ;;
            *:*)    [[ "${current_cmd}" = 'build' || "${current_cmd}" = 'dep-graph' || "${current_cmd}" = 'push' ]] && \
                        _bc_kubler_comp_namespace && _compopt_nospace && readarray -t COMPREPLY < <(compgen -W "${___bc_kubler_comp_namespace}" -- "${cur}")
                ;;
        esac
    fi
    return
}

_bc_kubler_init

[[ -z "${KUBLER_TEST_BIN}" ]] && complete -F _kubler kubler kubler.sh
true
