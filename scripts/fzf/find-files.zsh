#!/bin/env zsh

# 1. 能够解析常用的参数
# 2. 接受目录或文件
# 3. 尽可能地解释用户传入的参数(很完美，几乎完全避免了和文件名或模式冲突)
#   1. ,10xf, max-depth=10 --type=x --type=f
#   2. 1d,1h [1d,1h] 2024-04-20,2024-04-25
#   3. cc,py, extensions=cc ... 
#   4. h,, exclude=*.h
#   5. ,0 去除depth标志
#   6. ,hi 切换--hidden --no-ignore

REPORT=$CUSTOM_HOME/scripts/tools/report

report_info() { $REPORT --indent --level "info" -- "$@" > /dev/tty }
report_warn() { $REPORT --indent --level "warn" -- "$@" > /dev/tty }
report_help() { $REPORT --level "help" -- "$@" > /dev/tty; exit 0 }
report_error() { $REPORT --indent --level "error" -- "$@" 2> /dev/tty; exit 1 }

help() {
    local help_msg='usage: ff [OPTIONS] [DIRECTORIES or Files]

    OPTIONS:
        -g glob-based search
        -p full-path
        -t char set, file types dfxlspebc (-t t...)
        -T string, changed after time ( 1min 1h 1d(default) 2weeks "2018-10-27 10:00:00" 2018-10-27)
        -d int, max-depth
        -H bool, --hidden
        -I bool, --no-ignore
        -e extensions
        -E exclude glob pattern
        -o select + -O
        -q Cancel the first n matching file names (Optional default 1)

        --help 
        --window full none
        --split Explain the parameters passed in by the user as much as possible
        --args pass -> fd

    KEYBINDINGS:
        ctrl-s horizontal direction splitw
        ctrl-v vertical direction splitw
        alt-e subshell editor
        alt-enter open dirname file
        enter current open file
    '
    report_help "${(@f)help_msg}"
}

__split() {
    local item
    for item in "$@"; do 
        { [[ -e $item ]] && ((o_q-- < 1)) } && {
            [[ -d $item ]] && Directories+=$item || Files+=$item
            continue
        }
        ((o_split)) && [[ $item =~ , ]] && {
            if [[ $item =~ ^(\\.|[[:digit:]]+[mhdwMy]|[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}|[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}[[:space:]][[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}),(\\.|[[:digit:]]+[mhdwMy]|[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}|[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}[[:space:]][[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2})?$ ]]; then 
                [[ $item =~ ^[^.] ]] && o_args+="--changed-after=${item%,*}"
                [[ $item =~ [^.,]$ ]] && o_args+="--changed-before=${item#*,}"
            else
                while (($#item)); do
                    case $item in
                        ,#) break ;;
                        [[:lower:]]##,,*) o_excludes+="*.${item[(ws/,,/)1]}"; item=${item#*,,} ;;
                        [[:lower:]]##,*) o_extensions+=${item[(ws/,/)1]}; item=${item#*,} ;;
                        *)
                            [[ $item =~ h ]] && { ((idx=$o_args[(I)--hidden])) && unset "o_args[idx]" || o_args+=--hidden }
                            [[ $item =~ i ]] && { ((idx=$o_args[(I)--no-ignore])) && unset "o_args[idx]" || o_args+=--no-ignore }
                            [[ $item =~ [[:digit:]] ]] && { unset "o_args[${o_args[(i)--max-depth*]}]"; ((idx=${$(grep -oP '\d+' <<<$item)[(w)-1]})) && o_args+="--max-depth=$idx" } # 获取数字序列的最后一个
                            o_types+=( ${(u)${(s//)item}:#[[:digit:]hi,]} )
                            break
                            ;;
                    esac
                done
            fi
            continue
        }
        [[ -z $Pattern ]] || report_error "$item error, pattern is exists"
        Pattern=$item
    done
}

__handle_result() {
    local trigger_key files
    trigger_key=${"${(@f)Results}"[1]}
    files=(${"${(@f)Results}"[2,-1]})
    
    if [[ "alt-s" == $trigger_key ]]; then
        tmux splitw -bv ${EDITOR} $files
    elif [[ "alt-v" == $trigger_key ]]; then
        tmux splitw -bh ${EDITOR} $files    
    elif [[ "alt-enter" == $trigger_key ]]; then
        $EDITOR ${files[-1]:h} > /dev/tty < /dev/tty
    else
        $EDITOR $files > /dev/tty < /dev/tty
    fi
}

main() {
    local o_q o_extensions=() o_types=() o_excludes=() o_window o_split o_output o_args=()
    zparseopts -D -E -F -A zopts -- q:: g p t: T: d: H I u e: E: -window: -output -help -split -args: || exit 1
    setopt extended_glob

    (($+zopts[-g])) && o_args+="--glob"
    (($+zopts[-p])) && o_args+="--full-path"
    (($+zopts[-u])) && o_args+="-u"
    (($+zopts[-H])) && o_args+="--hidden"
    (($+zopts[-I])) && o_args+="--no-ignore"
    (($+zopts[-d])) && o_args+="--max-depth=$zopts[-d]"
    (($+zopts[-t])) && o_types+=( ${(s//)zopts[-t]} )
    (($+zopts[-T])) && o_args+="--change-after=$zopts[-T]"
    (($+zopts[-e])) && o_extensions+=( ${(s/,/)zopts[-e]} )
    (($+zopts[-E])) && o_excludes+=( ${(s/,/)zopts[-E]} )
    (($+zopts[-q])) && o_q=${zopts[-q]:-1}
    
    (($+zopts[--split]))  && o_split=1
    (($+zopts[--output])) && o_output=1
    (($+zopts[--window])) && o_window=$zopts[--window]
    (($+zopts[--args]))   && o_args+=(${=zopts[--args]})
    (($+zopts[--help]))   && help

    local Directories=() Files=() Pattern Results
    local fbin cmd fopts exitcode  
    
    (($#)) && __split "$@"
    
    [[ $o_window == full ]] && fbin=(fzf-tmux -p100%,100%) || fbin=(fzf-tmux $FZF_TMUX_OPTS)
    [[ $o_window == none ]] && fbin=

    cmd="command fd --color=always --follow $o_args"

    fopts="
    $FZF_DEFAULT_OPTS
    --prompt 'Files> '
    --exit-0
    --scheme path --exact --tiebreak \"length,end,chunk,index\"
    --delimiter / --nth -1,-2
    --header-first --header=\"keybindings:: C-s, C-v, C-o, A-e, A-enter\"
    --expect \"alt-s,alt-v,alt-o,alt-enter\"
    --bind=\"alt-e:execute(${EDITOR} {+} > /dev/tty < /dev/tty)\"
    --bind=\"alt-s:accept,alt-v:accept,alt-enter:accept,enter:accept\"
    --bind=\"one:select\"
    $FZF_CUSTOM_OPTS
    "
    
    Results=$( 
    { 
        (($#Files)) && lscolors <<<${(F)Files}
        (($#Directories || !$#Files)) && eval $cmd --type=${^o_types:-f} --extension=${^o_extensions} \"--exclude=${^o_excludes}\" \"${Pattern:-\^}\" $Directories
    } | FZF_DEFAULT_OPTS=$fopts ${fbin:-fzf})
    exitcode=$?

    if ((exitcode == 1)); then report_warn  "没有搜索到任何相关的文件";
    elif ((exitcode == 130)); then :;
    elif ((o_output)); then print $Results;
    else __handle_result;fi

    return $exitcode
}
main "$@"
