#!/bin/env zsh

# 1. 能够解析常用的参数
# 2. 接受目录或文件
# 3. 能够在fzf过滤时，解释--iglob --hidden --no-ignore --max-depth --type --type-not
# 4. 尽可能解释用户传入的参数
#   1. ,10 max-depth=10
#   2. cpp,c, --type=cpp 
#   3. cc,, --type-not=c
#   4. ,0 去除depth标志
#   5. ,hi 切换--hidden --no-ignore
# 5. 解决了\b的转义问题

REPORT=$CUSTOM_HOME/scripts/tools/report

report_info() { $REPORT --indent --level "info" "$@" > /dev/tty }
report_info_and_exit() { $REPORT --indent --level "info" "$@" > /dev/tty; exit 0 }
report_help() { $REPORT --level "help" "$@" > /dev/tty; exit 0 }
report_error() { $REPORT --indent --level "error" "$@" 2> /dev/tty; exit 1 }

__help() {
    local help_msg='usage: ss [OPTIONS] [pattern] [DIRECTORIES or Files]

    OPTIONS:
        -t file types,  Comma-separated
        -T file types(not),  Comma-separated
        -d int max-depth
        -H bool --hidden
        -I bool --no-ignore 
        -q Cancel the first n matching file names (Optional, default 1)
        -w world regex
        -u[uu] (Optional default -u)

        --help 
        --window full none
        --split Explain the parameters passed in by the user as much as possible
        --args pass -> rg

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
        [[ ((o_split)) && $item =~ , ]] && {
            while (($#item)); do
                case $item in
                    ,#) break ;;
                    [[:lower:]]##,,*) o_types+=--type-not=${item[(ws/,,/)1]}; item=${item#*,,} ;;
                    [[:lower:]]##,*) o_types+=--type=${item[(ws/,/)1]}; item=${item#*,} ;;
                    *)
                        [[ $item =~ h ]] && { ((idx=$o_dynamic[(I)--hidden])) && unset "o_dynamic[idx]" || o_dynamic+=--hidden }
                        [[ $item =~ i ]] && { ((idx=$o_dynamic[(I)--no-ignore])) && unset "o_dynamic[idx]" || o_dynamic+=--no-ignore }
                        [[ $item =~ [[:digit:]] ]] && { unset "o_dynamic[${o_dynamic[(i)--max-depth*]}]"; ((idx=${$(grep -oP '\d+' <<<$item)[(w)-1]})) && o_dynamic+="--max-depth=$idx" } # 获取数字序列的最后一个
                        break
                        ;;
                esac
            done
            continue
        }
        [[ -z $Pattern ]] || report_error "$item error, pattern is exists"
        Pattern=$item
    done
}

__handle_result() {
    local trigger_key file_path line_number
    trigger_key=${"${(@f)Results}"[1]}
    file_path=${Results[(f)-1][(ws/:/)1]}
    line_number=${(q)Results[(f)-1][(ws/:/)2]}
    
    if [[ "alt-s" == $trigger_key ]]; then
        tmux splitw -bv ${EDITOR} $file_path +$line_number
    elif [[ "alt-v" == $trigger_key ]]; then
        tmux splitw -bh ${EDITOR} $file_path +$line_number
    elif [[ "alt-enter" == $trigger_key ]]; then
        $EDITOR ${file_path:h} > /dev/tty < /dev/tty
    else
        $EDITOR $file_path +$line_number > /dev/tty < /dev/tty
    fi
}


main() {
    local o_q o_types=() o_dynamic=() o_window o_split o_args=()
    zparseopts -D -E -F -A zopts -- q:: w x u:: H I d: t: T: -window: -help -split -args: || exit 1
    setopt extended_glob

    (($+zopts[-w])) && o_args+="-w"
    (($+zopts[-x])) && o_args+="-x"
    (($+zopts[-u])) && o_args+="-u$zopts[-u]"
    (($+zopts[-H])) && o_dynamic+="--hidden"
    (($+zopts[-I])) && o_dynamic+="--no-ignore"
    (($+zopts[-d])) && o_dynamic+="--max-depth=$zopts[-d]"
    (($+zopts[-t])) && o_types+=( $(print -- --type=${^${(s/,/)zopts[-t]}}) )
    (($+zopts[-T])) && o_types+=( $(print -- --type-not=${^${(s/,/)zopts[-T]}}) )
    (($+zopts[-q])) && o_q=${zopts[-q]:-1}
    
    (($+zopts[--split]))  && o_split=1
    (($+zopts[--window])) && o_window=$zopts[--window]
    (($+zopts[--args]))   && o_args+=(${=zopts[--args]})
    (($+zopts[--help]))   && help
    
    local file_rg file_fzf file_preview_size
    local Directories=() Files=() Pattern Results
    local fbin cmd fopts exitcode  
    local change_preview change_reload toggle_search initial_search
    
    file_rg=/tmp/rg-$$
    file_fzf=/tmp/fzf-$$
    file_preview_size=/tmp/preview-size-$$
    trap "command rm -f $file_r $file_f $file_preview_size" EXIT SIGINT SIGTERM

    (($#)) && __split "$@"

    [[ $o_window == full ]] && fbin=(fzf-tmux -p100%,100%) || fbin=(fzf-tmux $FZF_GREP_TMUX_OPTS)
    [[ $o_window == none ]] && fbin=
    
    cmd="command rg --line-number --no-heading --color=always --smart-case $o_args"
    
    change_reload="
    setopt extended_glob
    local dynamic=($o_dynamic) types=($o_types) globs=()
    [[ \$FZF_QUERY == *--* ]] && for item in \${(s/ /)\${FZF_QUERY##*--}}; do 
        while ((\$#item)); do
            case \$item in
                ,#) break ;;
                h) ((idx=\$dynamic[(I)--hidden])) && unset \\\"dynamic[idx]\\\" || dynamic+=--hidden; item= ;;
                i) ((idx=\$dynamic[(I)--no-ignore])) && unset \\\"dynamic[idx]\\\" || dynamic+=--no-ignore; item= ;;
                <->) unset \\\"dynamic[\$dynamic[(i)--max-depth*]]\\\"; ((\$item)) && dynamic+=--max-depth=\$item; item= ;;
                [[:lower:]]##,,*) types+=--type-not=\${item[(ws/,,/)1]}; item=\${item#*,,} ;;
                [[:lower:]]##,*) types+=--type=\${item[(ws/,/)1]}; item=\${item#*,} ;;
                *) globs+=\\\"'--iglob=\$item'\\\"; item= ;;
            esac
        done
    done
    print -r \\\"reload($cmd \${(u)dynamic} \${(u)types} \${(u)globs} -- '\${\${FZF_QUERY%--*}%% #}' ${Directories} ${Files} || true)\\\"
    "

    change_preview="
    typeset lines=\$((FZF_LINES - 3))  match_count=\$FZF_MATCH_COUNT preview_lines=\${FZF_PREVIEW_LINES:-\${\$(<$file_preview_size):-0}}
    typeset b1=10000 b2=1000 b3=100 per1=0 per2=30 per3=60 result
    if ((match_count == 0 || match_count > b1)); then
        result=0
    elif ((match_count > b2)); then
        result=\$(( ((b1 - match_count) * (per2 - per1) / (b1 - b2)  + per1) * lines / 100 ))
    elif ((match_count > b3)); then
        result=\$(( ((b2 - match_count) * (per3 - per2) / (b2 - b3)  + per2) * lines / 100 ))
    elif ((match_count > (lines - preview_lines))); then
        result=\$preview_lines
    else
        result=$\((lines - match_count))
    fi
    [[ -z \$FZF_PREVIEW_LINES ]] && print \$result > $file_preview_size 
    print \\\"change-preview-window(\$result)\\\"
    "

    toggle_search="
    if [[ ! \$FZF_PROMPT =~ Rg ]]; then
        echo \\\"rebind(change)+change-prompt(Rg> )+disable-search+transform-query:echo -E \\\{q} > $file_fzf; cat $file_rg\\\"
    else
        echo \\\"unbind(change)+change-prompt(Fzf> )+enable-search+transform-query:echo -E \\\{q} > $file_rg; cat $file_fzf\\\"
    fi
    "

    initial_search="
    if [[ -z '\{q}' ]]; then
        echo \\\"ignore\\\"
    else
        echo \\\"reload:$cmd $o_dynamic $o_types -- \\\{q} ${Directories} ${Files}\\\"
    fi
    "

    fopts="
    $FZF_DEFAULT_OPTS
    --layout=reverse-list --disabled +m
    --query '$Pattern'
    --prompt \"Rg> \"
    --exact
    --bind=\"start:transform:$initial_search\"
    --bind \"change:transform:$change_reload\"
    --bind \"result:transform:$change_preview\"
    --bind \"resize:transform:$change_preview\"
    --bind \"ctrl-g:transform:$toggle_search\"
    --delimiter :
    --header-first --header=\"keybindings:: C-s, C-v, C-o, A-e, A-enter | pattern:: h i <-> *.cc cpp, c,, cpp,c,java,,\"
    --preview-window \"up:~1,+{2}/2:border-down\"
    --preview 'bat --style=numbers,header,changes,snip --color=always --highlight-line {2} -- {1}'
    --expect \"alt-s,alt-v,alt-o,alt-enter\"
    --bind=\"alt-e:execute(${EDITOR} {1} +{2} > /dev/tty < /dev/tty)\"
    --bind=\"alt-s:accept,alt-v:accept,alt-enter:accept,enter:accept\"
    $FZF_CUSTOM_OPTS
    "
    
    Results=$(: | FZF_DEFAULT_OPTS=$fopts ${fbin:-fzf})
    exitcode=$?

    ((exitcode == 1 || exitcode == 130)) || __handle_result 
    return $exitcode
}
main "$@"
