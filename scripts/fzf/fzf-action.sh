#!/bin/env bash

action::null() {
    return 0
}
action::editor() {
    typeset trigger_key dir

    trigger_key=$(grep -o -P "^(ctrl|alt)-\w$" < <(echo "$Results" | sed -n '1p'))
    [[ $trigger_key ]] && Results=$(echo "$Results" | sed -n '1!p')
    dir=$(echo "$Results" | sed -n '1p')

    if [[ "${trigger_key}" == "ctrl-f" ]]; then
        "$CUSTOM_HOME/scripts/fzf/find-files" $Flag_action ${Results}
    elif [[ "${trigger_key}" == "ctrl-g" ]]; then
        "$CUSTOM_HOME/scripts/fzf/search-string" $Flag_action ${Results}
    elif [[ "${trigger_key}" == "ctrl-s" ]]; then
        tmux splitw -bh zsh -c "${EDITOR} $Flag_action $dir"
    elif [[ "${trigger_key}" == "ctrl-v" ]]; then
        tmux splitw -bv zsh -c "${EDITOR} $Flag_action $dir"
    elif [[ "${trigger_key}" == "ctrl-o" ]]; then
        "$CUSTOM_HOME/scripts/tmux/tmux-menu" $Flag_action "$dir"
    else
        mkdir -p "$(dirname "$dir")" &> /dev/null
        "${EDITOR}" $Flag_action "$dir"
    fi
    return $?
}
action::marks() {
    typeset prefix trigger_key cmd bin_name

    prefix="$CUSTOM_HOME/scripts/fzf"
    trigger_key=$(grep -o -P "^(ctrl|alt)-\w$" < <(echo "$Results" | sed -n '1p'))
    [[ $trigger_key ]] && Results=$(echo "$Results" | sed -n '1!p')

    bin_name=$(grep -o -P '^@\S+' <<< "$Flag_action")
    if [[ -n "${bin_name}" ]]; then
        Flag_action="${Flag_action/#${bin_name} /}"
        bin_name="${bin_name/#@/}"
        [[ -x "$prefix/$bin_name" ]] && cmd="$prefix/$bin_name" || cmd="$bin_name"
    fi

    if [[ "${trigger_key}" == "ctrl-f" ]]; then
        [[ -x "$prefix/find-files" ]] && cmd="$prefix/find-files"
    elif [[ "${trigger_key}" == "ctrl-g" ]]; then
        [[ -x "$prefix/find-files" ]] && cmd="$prefix/search-string"
    else
        if [[ -z ${bin_name} ]]; then
            echo "executable file is not exists" > /dev/tty
            exit 1
        fi
        [[ ! -x "$cmd" ]] && (
            echo "$cmd is not a executable file" > /dev/tty
            exit 1
        )
    fi
    $cmd $Flag_action -- $Results
    return $?
}

env::null() {
    echo ""
}
env::editor() {
    action_f="execute($CUSTOM_HOME/scripts/fzf/find-files ${Flag_env} {+})"
    action_g="execute($CUSTOM_HOME/scripts/fzf/search-string ${Flag_env} {+})"
    echo "
    --header-first
    --header \"keybindings: C-f(find files), C-g(grep string), C-s(hsp), C-v(vsp), C-o(fzf-tmux-menu), A-e(execute editor), Enter(editor|print)\"
    --expect \"ctrl-s,ctrl-v,ctrl-o${fzf_bin:+,ctrl-f,ctrl-g}\"
    --bind=\"ctrl-f:${action_f:-accept}\"
    --bind=\"ctrl-g:${action_g:-accept}\"
    --bind=\"alt-e:execute(${EDITOR} {+} > /dev/tty < /dev/tty)\"
    --bind=\"ctrl-s:accept\"
    --bind=\"ctrl-v:accept\"
    --bind=\"ctrl-o:accept\"
    --bind=\"enter:accept-or-print-query\" 
    "
}
env::marks() {
    echo "
    --header-first
    --header \"keybindings: C-f(find files), C-g(grep string), Enter(editor)\"
    --expect \"ctrl-f,ctrl-g\"
    --bind=\"ctrl-f:accept\"
    --bind=\"ctrl-g:accept\"
    --bind=\"enter:accept\" 
    "
}

help() {
    echo "Usage: script_name MODE [OPTIONS]
        -P no-popup 
        -a args. pass to action
        -A args. pass to env
    "
}

main() {
    [[ -v TMUX ]] && command -v fzf-tmux &> /dev/null && fzf_bin="fzf-tmux $FZF_TMUX_OPTS"

    typeset Flag_P Flag_action Flag_env Results
    typeset Env Action Exit_code

    args=$(getopt -o Pa:A: -n "$0" -- "$@")
    eval set -- "$args"

    while true; do
        case $1 in
        -P)
            fzf_bin=
            Flag_P=1
            shift
            ;;
        -a)
            Flag_action+="$2 "
            shift 2
            ;;
        -A)
            Flag_env+="$2 "
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "arg error"
            exit 1
            ;;
        esac
    done

    case $MODE in
    zoxide | git)
        Env=editor Action=editor
        ;;
    marks)
        Env=marks Action=marks
        ;;
    esac

    Results=$( (
        FILTER_FZF_DEFAULT_OPTS="$(env::${Env:-null})" fzf-filter "$MODE" ${Flag_P:+-P} "$@"
        Exit_code=$?
    ) | grep -v "^$")
    [[ $Exit_code -ne 130 ]] && [[ ${Results} ]] && action::${Action:-null}
}

if [[ -z $1 && $1 == help ]]; then
    help > /dev/tty
    exit 0
fi

if [[ -z $1 || " $(fzf-filter list) " != *"$1"* ]]; then
    echo "$1 is invalid"
    exit 1
fi

MODE=$1
shift

main "$@"
