#!/bin/env bash

action::null() {
    return 0
}
action::editor() {
    if [[ ${#Results[@]} -eq 1 ]]; then
        mkdir -p "$(dirname "${Results[0]}")" &> /dev/null
        "${EDITOR}" "${Results[@]}" > /dev/tty < /dev/tty
        return 0
    fi
    trigger_key=${Results[0]}
    unset "Results[0]"

    if [[ "${trigger_key}" == "ctrl-f" ]]; then
        "$CUSTOM_HOME/scripts/fzf/find-files" "${Results[@]}"
    elif [[ "${trigger_key}" == "ctrl-g" ]]; then
        "$CUSTOM_HOME/scripts/fzf/search-string" "${Results[@]}"
    elif [[ "${trigger_key}" == "ctrl-s" ]]; then
        tmux splitw "-bh" zsh -c "${EDITOR} ${Results[1]}"
    elif [[ "${trigger_key}" == "ctrl-v" ]]; then
        tmux splitw "-bv" zsh -c "${EDITOR} ${Results[1]}"
    elif [[ "${trigger_key}" == "ctrl-o" ]]; then
        "$CUSTOM_HOME/scripts/tmux/tmux-menu" "${Results[1]}"
    else
        "${EDITOR}" "${Results[1]}"
    fi
}
action::marks() {
    $1 "${@:2}" -- "${Results[@]:-home}"
}

env::null() {
    echo ""
}
env::editor() {
    action_f="execute($CUSTOM_HOME/scripts/fzf/find-files ${Flag_nopopup:+-P} {+})"
    action_g="execute($CUSTOM_HOME/scripts/fzf/search-string ${Flag_nopopup:+-P} {+})"
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

main() {
    [[ -v TMUX ]] && command -v fzf-tmux &> /dev/null && fzf_bin="fzf-tmux $FZF_TMUX_OPTS"

    typeset Flag_nopopup Flag_P Flag_before_args Flag_after_args Results
    typeset Env Action Args

    args=$(getopt -o PA:a: -l no-popup: -n "$0" -- "$@")
    eval set -- "$args"

    while true; do
        case $1 in
        -P)
            fzf_bin=
            Flag_P=1
            shift
            ;;
        --no-popup)
            Flag_nopopup=1
            shift
            ;;
        -a)
            Flag_after_args="$2"
            shift 2
            ;;
        -A)
            Flag_before_args="$2"
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
        Action="marks"
        [[ ! $Flag_before_args =~ "^/" ]] && prefix="$CUSTOM_HOME/scripts/fzf/"
        Args="$prefix$Flag_before_args $Flag_after_args"
        ;;
    esac

    readarray -t Results < <(FILTER_FZF_DEFAULT_OPTS="$(env::${Env:-null})" fzf-filter "$MODE" ${Flag_P:+-P} "$@")

    [[ ${#Results[@]} -gt 0 ]] && action::${Action:-null} "${Args:-}"
}

if [[ -z $1 || " $(fzf-filter list) " != *"$1"* ]]; then
    echo "$1 is invalid"
    exit 1
fi

MODE=$1
shift

main "$@"
