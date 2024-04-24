#!/bin/env zsh

typeset -A LOG=(
    info  42
    error 15
    help 32
)
FD_BIN=$CUSTOM_HOME/scripts/fzf/find-files
ERROR_FILE=/tmp/error-$$ && trap "rm -f $ERROR_FILE" EXIT SIGINT SIGTERM
valid_command=(rm cp mv)

report() {
    local level
    (($# && $+LOG[$1])) && {
        print -P "%S%B%F{${LOG[$1][1]}}$1:%s%f%b"
        level=$1
        shift
    }
    (($#)) && print -P "%F{${LOG[$level][2]:-6}}$(print -l ${level:+\\\t}${^@})%f"
}
report_info() { report "info" "$@" > /dev/tty }
report_help() { report "help" "$@" > /dev/tty; exit 0 }
report_error() { report "error" "$@" 2> /dev/tty; exit 1 }

__rm__() {
    local flag_args cmd fopts results
    zparseopts -E -D -F -A zopts -- v r f i -help -cmd: 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}"

    (($+zopts[--help])) && report_help "args: -v -f -r -i"
    (($+zopts[--cmd])) && cmd=$zopts[--cmd]
    (($+zopts[-v])) && flag_args+="-v "
    (($+zopts[-f])) && flag_args+="-f "
    (($+zopts[-i])) && flag_args+="-i "
    (($+zopts[-r])) && flag_args+="-r "

    cmd="command ${cmd:-rm} $flag_args"
    fopts="--prompt \"To-Rm > \" "

    results=$(FZF_CUSTOM_OPTS=$fopts $FD_BIN -O --split -d1 -t "$@")
    
    [[ -n $results ]] && { eval $cmd ${(f)results} 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}" }
}
__cp__() {
    local flag_args cmd fopts results
    zparseopts -E -D -F -A zopts -- v r f i b u t: -help -cmd: 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}" 
    (($+zopts[--help])) && report_help "args: -v -f -i -r -b -u -t"
    (($+zopts[--cmd])) && cmd=$zopts[--cmd]
    (($+zopts[-v])) && flag_args+="-v "
    (($+zopts[-f])) && flag_args+="-f "
    (($+zopts[-i])) && flag_args+="-i "
    (($+zopts[-r])) && flag_args+="-r "
    (($+zopts[-b])) && flag_args+="-b "
    (($+zopts[-u])) && flag_args+="-u "
    (($+zopts[-t])) && flag_args+="-t $zopts[-t] " || report_error "Need a specified directory"

    cmd="command ${cmd:-cp} $flag_args"
    fopts="--prompt \"To-Cp > \" "

    results=$(FZF_CUSTOM_OPTS=$fopts $FD_BIN -O --split -d1 -t -E $zopts[-t] "$@")
    
    [[ ! -d $zopts[-t] ]] && { mkdir -p $zopts[-t] 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}" }
    [[ -n $results ]] && { eval $cmd ${(f)results} 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}" }
}

__mv__() {
    local flag_args cmd fopts results
    zparseopts -E -D -F -A zopts -- v n f i b u t: -help -cmd: 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}" 
    (($+zopts[--help])) && report_help "args: -v -f -i -n -b -u -t"
    (($+zopts[--cmd])) && cmd=$zopts[--cmd]
    (($+zopts[-v])) && flag_args+="-v "
    (($+zopts[-f])) && flag_args+="-f "
    (($+zopts[-i])) && flag_args+="-i "
    (($+zopts[-n])) && flag_args+="-n "
    (($+zopts[-b])) && flag_args+="-b "
    (($+zopts[-u])) && flag_args+="-u "
    (($+zopts[-t])) && flag_args+="-t $zopts[-t] " || report_error "Need a specified directory"

    cmd="command ${cmd:-mv} $flag_args"
    fopts="--prompt \"To-Mv > \" "

    results=$(FZF_CUSTOM_OPTS=$fopts $FD_BIN -O --split -d1 -t -E $zopts[-t] "$@")
    
    [[ ! -d $zopts[-t] ]] && { mkdir -p $zopts[-t] 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}"  }
    [[ -n $results ]] && { eval $cmd ${(f)results} 2> $ERROR_FILE || report_error "${(f@)$(<$ERROR_FILE)}" } 
}

(($# && ${valid_command[(I)$1]})) || report_error "command is empty or error"
mode=$1
shift
__${mode}__ "$@"
