#!/bin/env bash

FD_BIN=$CUSTOM_HOME/scripts/fzf/find-files
FD_OPTS="q::gpP"
FD_LOPTS=""
FD_ARGS=(-Ht -d1 --split -O)

__rm__() {
    typeset cmd flag_cmd_args flag_fd_args
    args=$(getopt -o vrfi"$FD_OPTS" -l help,cmd::"$FD_LOPTS" -n "$0" -- "$@")
    eval set -- "$args"

    while true; do
        case $1 in
        --cmd)
            [[ $2 ]] && cmd=$2 || cmd="rm"
            shift 2
            ;;
        -v | -f | -r | -i)
            flag_cmd_args+="$1 "
            shift
            ;;
        --)
            shift
            break
            ;;
        --help)
            echo " -v | -f | -r | -i " > /dev/tty
            exit 0
            ;;
        *)
            flag_fd_args+="$1 "
            shift
            ;;
        esac
    done

    typeset results opts

    cmd="command ${cmd:-rm -r} $flag_cmd_args"
    opts="
    --prompt \"To-Rm > \"
    "

    # shellcheck disable=SC2086
    results=$(FZF_CUSTOM_OPTS=$opts $FD_BIN "$@" "${FD_ARGS[@]}" $flag_fd_args | grep -v "^$" | tr '\n' ' ')

    [[ "$results" ]] && eval "$cmd $results > /dev/tty < /dev/tty"
}

__cp__() {
    typeset cmd flag_cmd_args flag_fd_args flag_target
    args=$(getopt -o vfiburt:"$FD_OPTS" -l help,cmd::"$FD_LOPTS" -n "$0" -- "$@")
    eval set -- "$args"

    while true; do
        case $1 in
        --cmd)
            [[ $2 ]] && cmd=$2 || cmd="cp"
            shift 2
            ;;
        -v | -r | -u | -f | -i | -b)
            flag_cmd_args+="$1 "
            shift
            ;;
        -t)
            flag_target+=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        --help)
            echo "-v | -r | -u | -f | -i | -b" > /dev/tty
            exit 0
            ;;
        *)
            flag_fd_args+="$1 "
            shift
            ;;
        esac
    done

    typeset results opts prompt_msg

    prompt_msg="Need a specified directory"
    cmd="command ${cmd:-cp -a} --target-directory=${flag_target:?$prompt_msg} $flag_cmd_args"
    opts="
    --prompt \"To-Cp > \"
    "

    # shellcheck disable=SC2086
    results=$(FZF_CUSTOM_OPTS=$opts $FD_BIN "$@" "${FD_ARGS[@]}" $flag_fd_args | grep -v "^$" | tr '\n' ' ')

    [[ "$results" ]] && eval "$cmd $results > /dev/tty < /dev/tty"
}

__mv__() {
    typeset cmd flag_cmd_args flag_fd_args flag_target
    args=$(getopt -o vuifbnt:"$FD_OPTS" -l help,cmd::"$FD_LOPTS" -n "$0" -- "$@")
    eval set -- "$args"

    while true; do
        case $1 in
        --cmd)
            [[ $2 ]] && cmd=$2 || cmd="mv"
            shift 2
            ;;
        -v | -u | -f | -i | -n | -b)
            flag_cmd_args+="$1 "
            shift
            ;;
        -t)
            flag_target=$2
            shift 2
            ;;
        --help)
            echo "-v |  -u | -f | -i | -n | -b" > /dev/tty
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            flag_fd_args+="$1 "
            shift
            ;;
        esac
    done

    typeset results opts prompt_msg

    prompt_msg="Need a specified directory"
    cmd="command ${cmd:-mv --backup=numbered} --target-directory=${flag_target:?$prompt_msg} $flag_cmd_args"
    opts="
    --prompt \"To-Mv > \"
    "

    # shellcheck disable=SC2086
    results=$(FZF_CUSTOM_OPTS=$opts $FD_BIN "$@" "${FD_ARGS[@]}" $flag_fd_args | grep -v "^$" | tr '\n' ' ')

    [[ "$results" ]] && eval "$cmd $results > /dev/tty < /dev/tty"
}

valid_command=(
    "rm"
    "cp"
    "mv"
)

[[ "${valid_command[*]}" != *"$1"* ]] && {
    echo "command error" &> /dev/tty
    return 1
}

MODE=$1
shift

"__${MODE}__" "$@"
