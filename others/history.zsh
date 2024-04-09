# 目录选择前500条记录，全局选择前3000条记录 local > glob
function search_command_history() {
    emulate -L zsh
    setopt EXTENDED_GLOB

    [[ $TMUX ]] && fzf_bin=(fzf-tmux $FZF_TMUX_OPTS)
    [[ $tmp_histfile ]] || tmp_histfile=/tmp/tmp_histfile

    [[ -r $HISTFILE ]] && command tail -3000 $HISTFILE > $tmp_histfile
    [[ -r "$_per_directory_history_path" ]] && command tail -500 $_per_directory_history_path >> $tmp_histfile

    result=$(
        ${fzf_bin:-fzf} +m \
            --scheme history --exact \
            --bind='enter:accept' \
            --prompt="Hist> " < <(command cat $tmp_histfile |
                tac | awk 'BEGIN{FS=";"}!x[$2]++{print $2}' | sed '/^.\{1,3\}$/d' | lscolors)
    )

    # 需要，不然画面不完整
    zle reset-prompt
    [[ -n $result ]] && {
        LBUFFER=$result
    }
}

zle -N search_command_history

bindkey -M viins '^O' search_command_history
