1. fm ./fzf/find-manpagers 查找manpagers
2. fo ./fzf/find-oldfiles 查找nvim打开的旧文件
3. fg ./fzf/find-gitfiles 查找当前所处git仓库的文件
4. ff ./fzf/find-files 查找文件
5. ss ./fzf/search-string 搜索文本
6. ja ./fzf/directores-actions 选择directores + actions

# install

`git clone https://github.com/MaJinjie/fzf-scripts.git $CUSTOM_HOME/scripts`

# usage

## 1 aliases

```bash
alias fm="$CUSTOM_HOME/scripts/fzf/find-manpagers"
alias fo="$CUSTOM_HOME/scripts/fzf/find-oldfiles"
alias ff="$CUSTOM_HOME/scripts/fzf/find-files"
alias fg="$CUSTOM_HOME/scripts/fzf/find-gitfiles"
alias ja="$CUSTOM_HOME/scripts/fzf/directores-actions"
alias ss="$CUSTOM_HOME/scripts/fzf/search-string"

```

**or**

```zsh
typeset -A fd rg
exec_aliases() {
    for exec_name ("$@") {
        if [[ ${+commands[$exec_name]} ]] {
            for k v (${(kvP)exec_name}) {
                aliases[${k}]=$v
            }
        }
    }
}

fd=(
    fm "$CUSTOM_HOME/scripts/fzf/find-manpagers"
    fo "$CUSTOM_HOME/scripts/fzf/find-oldfiles"
    ff "$CUSTOM_HOME/scripts/fzf/find-files"
    fg "$CUSTOM_HOME/scripts/fzf/find-gitfiles"
    ja "$CUSTOM_HOME/scripts/fzf/directores-actions"
)

rg=(
    ss "$CUSTOM_HOME/scripts/fzf/search-string"
)

exec_aliases "fd" "rg"
```

## 2 PATH

add to env PATH

# fzf

## 1 find-manpagers

`fm init-query`

### keybindings

- `enter` 使用EDITOR打开

## 2 find-oldfiles

使用了fzf中的交互式模糊查询和非交互式过滤查询。

拥有以下三种使用方式：

1. `fo -` 直接打开最近打开的文件
2. `fo init-query` 直接打开非交互式过滤搜索的第一个文件
3. `fo` 进入交互式模糊查询

```bash
# 下面的从上到下，最近打开的文件
# /home/mjj/dotfiles/.local/scripts/.gitignore
# /home/mjj/dotfiles/.local/scripts/fzf/directores-actions
# /home/mjj/dotfiles/.config/zsh/.zshenv
# /home/mjj/dotfiles/.config/zsh/zsh.d/41-aliases.zsh
# /home/mjj/dotfiles/.config/zsh/zsh.d/70-export-plug.zsh
# /home/mjj/dotfiles/.local/bin/nvim/ss
# /home/mjj/.config/custom/directores.toml

fo - # open /home/mjj/dotfiles/.local/scripts/.gitignore
fo toml # open /home/mjj/.config/custom/directores.toml
fo zsh # open  /home/mjj/dotfiles/.config/zsh/.zshenv
```

### 流程

1. 从nvim中读取旧文件列表
2. 过滤，得到非临时、存在、可读的文件
3. fzf + action

### keybindings

- `C-x` 将文件的目录复制到查询中（以便创建给定目录的文件)

- `enter` 使用EDITOR打开已选择的文件或新建未查询到的文件

```bash
--bind="enter:accept-or-print-query" | sed -n "${*:+1}p"
```

- `C-s|h` 使用tmux垂直或水平分割文件

```bash
tmux splitw "-b${flag}" zsh -c "${EDITOR} ${files[*]}"
```

- `C-o` 使用tmux菜单打开文件

- `A-e` 在非fzf-tmux时使用`execute`打开

## find-gitfiles

类似于find-oldfiles， 文件列表是当前git仓库的文件。
其中，文件列表使用`git ls-files --[flags]`得到。

### options

```bash
usage: fg [OPTIONS] [init_query]

    OPTIONS:
        -m + --modified
        -d + --deleted
        -s + --stage
        -k + --killed
        -o + --others
        -i + --ignored
```

## find-files

> 最核心的两个脚本之一

```bash
usage: ff [OPTIONS] [DIRECTORES] [--] [DIRECTORY MARKS]

    OPTIONS:
        -t char set, file types dfxlspebc
        -T string, changed after time ( 1min 1h 1d(default) 2weeks "2018-10-27 10:00:00" 2018-10-27)
        -D int, max-depth
        -h bool, cancel --hidden
        -n bool, --no-ignore
        -q string, init_query

        --
        add marks ...
    KEYBINDINGS:
        ctrl-s horizontal direction splitw
        ctrl-v vertical direction splitw
        ctrl-x transform-query:echo $(dirname {})/
        alt-e fzf-tmux-menu splitw

```

它拥有以下特性：

1. 能够解析`fd` 几个比较实用的选项
2. 可以查找指定相对目录或绝对目录
3. 添加了目录标志。

### 目录标志

> 通过一个关键字来标识一个或多个目录，传入关键字即指定了对应的目录。

1. 它在运行时解析，意味着他可以是在子进程中执行的shell命令。

2. 它定义在`toml`文件的`[marks]` 表中

目前接受以下几种形式

```bash
[marks]
nv = "$HOME/.config/${NVIM_APPNAME:-nvim}/lua"
home = "$HOME"
git = "$(git rev-parse --show-toplevel)" # 返回当前git仓库所在目录
arr = ['aa', 'bb']
# 注意 [和]后不能有空格
test_arr = [
  "$HOME/.local/bin",
  "$XDG_CONFIG_HOME/nvim"
]
```

## search-string

交互式查找字符串

```bash
usage: ss [OPTIONS] [DIRECTORES] [--] [DIRECTORY MARKS]

    OPTIONS:
        -t bool types files,  Comma-separated
        -D int max-depth
        -h bool cancel --hidden
        -n bool --no-ignore
        -q char*|string init_query

        --
        add marks ...
    KEYBINDINGS:
        ctrl-s horizontal direction splitw
        ctrl-v vertical direction splitw
        alt-e fzf-tmux-menu splitw

```

它拥有以下特性：

1. 能够解析`rg` 几个比较实用的选项
2. 可以查找指定相对目录或绝对目录
3. 添加了目录标志。
4. 可以在交互式查询时过滤特定模式的文件，以及拼接多个正则表达式。

默认使用`--`过滤文件模式、`&` 拼接多个正则 `.*?` 连接多个正则。分别使用以下三个变量定义，`CUSTOM_REGEX_SEPARATE CUSTOM_IGLOB_SEPARATE CUSTOM_CONNECT_REGEX`

解析过程如下，使用while循环解析，因此，对`-- &`可以在任意位置，可以有多个。

```bash
    regex_separate="${CUSTOM_REGEX_SEPARATE:-&}"
    iglob_separate="${CUSTOM_IGLOB_SEPARATE:---}"
    connect_regex="${CUSTOM_CONNECT_REGEX:-.*?}"

    transform_iglob="
    setopt extended_glob
    fzf_query=\${\${FZF_QUERY## ##}%% ##}
    let i=len=flag=0
    while [[ i -lt \${#fzf_query} ]]; do
        if [[ \${fzf_query:\$i:${#regex_separate}} == '${regex_separate}' || \${fzf_query:\$i:${#iglob_separate}} == '${iglob_separate}' ]]; then
            if [[ flag -eq 0 ]]; then
                append_str=\"\${\${\${fzf_query:\$[i-len]:\$len}## ##}%% ##}\"
                search_str+=\"\${append_str:+\${search_str:+${connect_regex}}}\$append_str\"
            else
                for iglob_entry in \${(s/ /)\${fzf_query:\$[i-len]:\$len}}
                do
                    case \$iglob_entry in
                    *)
                        iglob_str+=\"'--iglob=\$iglob_entry' \"
                        ;;
                    esac
                done
            fi
            [[ \${fzf_query:\$i:${#regex_separate}} == '${regex_separate}' ]] && let flag=0,len=0,i+=${#regex_separate}
            [[ \${fzf_query:\$i:${#iglob_separate}} == '${iglob_separate}' ]] && let flag=1,len=0,i+=${#iglob_separate}
        else
            let len++,i++
        fi
    done
    if [[ len -gt 0 ]]; then
        if [[ flag -eq 0 ]]; then
            append_str=\"\${\${\${fzf_query:\$[i-len]:\$len}## ##}%% ##}\"
            search_str+=\"\${append_str:+\${search_str:+${connect_regex}}}\$append_str\"
        else
            for iglob_entry in \${(s/ /)\${fzf_query:\$[i-len]:\$len}}
            do
                iglob_str+=\"'--iglob=\$iglob_entry' \"
            done
        fi
    fi
    echo \"reload:sleep 0.1;${rg_prefix} \${iglob_str} '\$search_str' ${directores[*]} || true\"
    "
```

## directores-actions

目录选择 + 执行动作

### 目录选择

1. 从zoxide中选择目录。 (实现，默认)
2. 从系统中的所有git仓库选择目录。（未实现）

### 执行动作

1. find-files。使用find-files脚本
2. search-string。使用search-string脚本
3. 分割窗口打开
4. 菜单打开
5. 打开现有或打开一个新的目录

**如想要添加新的目录选择，请定义一个函数，添加一个选项去处理即可。**

# tmux

## fzf-tmux-menu

使用tmux菜单实现9种方式拆分,可以集成到上述脚本中使用
`top bottom left right fulltop fullbottom fullleft fullright new-window`

# 注意

## 1 变量

1. 目录标志定义的优先级为`$CUSTOM_MARKS_FILE > $XDG_CONFIG_HOME/custom/directores.toml > $HOME/.config/custom/directores.toml` 中。
   具体为：`${CUSTOM_MARKS_FILE:-${XDG_CONFIG_HOME:-${HOME}/.config}/custom/directores.toml}`
2. `CUSTOM_HOME` ，其中 fzf脚本位于`$CUSTOM_HOME/scripts/fzf` tmux脚本位于`$CUSTOM_HOME/scripts/tmux`。
   如果需要直接修改脚本`exec_action`函数即可

## 2 fzf变量

1. 非特殊情况，都是使用`--exact`标志进行精确匹配（匹配效果好）
2. 文件路径都使用`--tiebreak end,chunk,index`，在进行交互时，从后往前开始输入。
3. 文件路径都使用`--scheme path`，find-oldfiles除外。
4. 通过提供`FZF_TMUX_OPTS` 和 `fzf-tmux` 来使用tmux弹出窗口查询
5. fzf的版本不得低于0.46.1，如何执行失败请使用更高版本。

这里附上我的`FZF_DEFAULT_OPTS`

```bash
FZF_COLORS="--color=hl:yellow:bold,hl+:yellow:reverse,pointer:032,marker:010"
FZF_HISTFILE="$XDG_CACHE_HOME/fzf/history"
FZF_FILE_PREVIEW="([[ -f {} ]] && (bkt --ttl 1m -- bat --style=numbers --color=always -- {}))"
FZF_DIR_PREVIEW="([[ -d {} ]] && (bkt --ttl 1m -- eza --color=always -TL4  {} | bat --color=always))"
FZF_BIN_PREVIEW="([[ \$(file --mime-type -b {}) = *binary* ]] && (echo {} is a binary file))"

export FZF_COLORS FZF_HISTFILE FZF_FILE_PREVIEW FZF_DIR_PREVIEW FZF_BIN_PREVIEW


# return
export FZF_DEFAULT_OPTS=" \
--marker='▍' \
--scrollbar='█' \
--ellipsis='' \
--cycle \
$FZF_COLORS \
--reverse \
--info=inline \
--ansi \
--multi \
--height=80% \
--tabstop=4 \
--scroll-off=2 \
--history=$FZF_HISTFILE \
--jump-labels='abcdefghijklmnopqrstuvwxyz' \
--preview-window :hidden \
--preview=\"($FZF_FILE_PREVIEW || $FZF_DIR_PREVIEW) 2>/dev/null | head -300\" \
--bind='home:beginning-of-line' \
--bind='end:end-of-line' \
--bind='tab:toggle+down' \
--bind='btab:up+toggle' \
--bind='esc:abort' \
--bind='ctrl-u:unix-line-discard' \
--bind='ctrl-w:backward-kill-word' \
--bind='ctrl-y:execute-silent(wl-copy -n {+})' \
--bind='ctrl-/:change-preview-window(up,60%,border-horizontal|right,60%,border-vertical)' \
--bind='ctrl-\:toggle-preview' \
--bind='ctrl-q:abort' \
--bind='ctrl-l:clear-selection+first' \
--bind='ctrl-j:down' \
--bind='ctrl-k:up' \
--bind='ctrl-x:replace-query' \
--bind='ctrl-p:prev-history' \
--bind='ctrl-n:next-history' \
--bind='ctrl-d:half-page-down' \
--bind='alt-j:preview-down' \
--bind='alt-k:preview-up' \
--bind='ctrl-b:beginning-of-line' \
--bind='ctrl-e:end-of-line' \
--bind='alt-a:toggle-all' \
--bind='alt-s:toggle-sort'
--bind='alt-w:toggle-preview-wrap'
--bind='alt-b:preview-page-up' \
--bind='alt-f:preview-page-down' \
--bind='?:jump' \
--bind 'enter:accept' \
"
export FZF_TMUX_OPTS="-p70%,80%"

```

## 其他

1. 如果没有`lscolors`, 请使用对应的包管理工具下载或访问https://github.com/sharkdp/lscolors下载。
