#!/usr/bin/env bash

exec_action() {
    # Get or create session
    if [[ $RESULT == *":"* ]]; then
        # RESULT comes from list-sessions
        SESSION=$(echo "$RESULT" | cut -d: -f1)
    # RESULT is a path
    elif [[ -d "$RESULT" ]]; then
        zoxide add "$RESULT"

        SESSION_NAME=$(echo "$RESULT" | sed "s#$HOME/#~#")
        SESSION_NAME=${SESSION_NAME:0:1}$(echo "${SESSION_NAME:1}" | awk -F/ 'NF>1{printf("%s-",$(NF-1))}END{printf("%s\n",$NF)}')

        SESSION=$(echo "${SESSION_NAME/# \//}" | tr . _ | tr ' ' _ | tr ':' _ | tr '[:upper:]' '[:lower:]')
        if ! tmux has-session "-t=$SESSION" 2> /dev/null; then
            tmux new-session -d -s "$SESSION" -c "$RESULT"
        fi
    else
        SESSION="$RESULT"
        tmux new-session -d -s "$SESSION" -c "$PWD"
    fi

    # Attach to session
    if [ -z "$TMUX" ]; then
        tmux attach -t "$SESSION"
    else
        tmux switch-client -t "$SESSION"
    fi
}
main() {
    typeset preview_cmd opts

    preview_cmd="($FZF_DIR_PREVIEW || (
    session_name=\$(cut -d: -f1 <<<{})
    while read -r window; do
        window_name=\$(echo \"\$window\" | cut -d: -f1)
        echo \\\"\$window\\\"
        while read -r pane; do 
            echo ' -> '\$pane
        done < <(tmux list-panes -t \$session_name:\$window_name)
    done< <(tmux list-windows -t \$session_name)
    )) 2> /dev/null"
    opts="
    --prompt \"Attach|New >\"
    --preview=\"$preview_cmd\"
    --bind=\"enter:accept-or-print-query\"
    --bind=\"alt-enter:print-query\"
    +m
    "

    if [[ $# -eq 1 && $1 == "-" ]]; then
        RESULT="$PWD"
    else
        RESULT=$(
            tmux list-sessions -F "#{session_last_attached} #{session_name}: #{session_windows} window(s)\
            #{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached, (attached),}" |
                sort -r | (if [ -n "$TMUX" ]; then grep -v " $(tmux display-message -p '#S'):"; else cat; fi) | cut -d' ' -f2- |
                FILTER_FZF_DEFAULT_OPTS="$opts" fzf-filter zoxide ${TMUX_POPUP:+-P} --before "$@" | tail -n 1
        )
    fi
    [[ "$RESULT" ]] && exec_action

    return "$?"
}

main "$@"
