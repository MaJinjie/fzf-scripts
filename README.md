1. fm ./fzf/find-manpagers 查找manpagers
2. fo ./fzf/find-oldfiles 查找nvim打开的旧文件
3. fg ./fzf/find-gitfiles 查找当前所处git仓库的文件
4. ff ./fzf/find-files 查找文件
5. ss ./fzf/search-string 搜索文本
6. fzf-filter 执行命令 + 过滤功能(实时或后台)
7. fzf-action.sh 对过滤后的条目选择性地执行定义的动作(相当于后端执行程序)

# install

`git clone https://github.com/MaJinjie/fzf-scripts.git $CUSTOM_HOME/scripts`

# usage

## 1 aliases

```bash
alias fm="$CUSTOM_HOME/scripts/fzf/find-manpagers"
alias fo="$CUSTOM_HOME/scripts/fzf/find-oldfiles"
alias ff="$CUSTOM_HOME/scripts/fzf/find-files"
alias fg="$CUSTOM_HOME/scripts/fzf/find-gitfiles"
alias ss="$CUSTOM_HOME/scripts/fzf/search-string"
alias fk="$CUSTOM_HOME/scripts/fzf/fzf-action.sh marks -A find-files"
alias sk="$CUSTOM_HOME/scripts/fzf/fzf-action.sh marks -A search-string"


alias di="$CUSTOM_HOME/scripts/fzf/fzf-action.sh zoxide"
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
# /home/mjj/.config/custom/directories.toml

fo - # open /home/mjj/dotfiles/.local/scripts/.gitignore
fo toml # open /home/mjj/.config/custom/directories.toml
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

**新增了以下功能**：

1. 为文件增加增加git状态，同时保留文件的颜色
2. `c-g`显示git仓库未跟踪文件
3. `?`切换为git操作模式，按压`AUM`，分别对选中的文件执行`git add | git restore --staged | git restore`
4. 修改了预览视图，命令为`git diff --color=always }`
   - .M 显示暂存区和工作区的差异
   - M. 查看暂存区和版本库之间的差异
   - 其他 bat

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
usage: ff [OPTIONS] [DIRECTORIES or Files]

OPTIONS:
    -t char set, file types dfxlspebc
    -T string, changed after time ( m h d w M y min day days week ... "2018-10-27 10:00:00" 2018-10-27)
    -d int, max-depth
    -H bool, --hidden
    -I bool, --no-ignore
    -P no-popup
    -F full-window
    -e extensions
    -E exclude glob pattern
    -O output to stdout

    --help
    --split Explain the parameters passed in by the user as much as possible \
       priority: file_and_directory > max_depth > type > depth_and_type > change_time > extensions
    --extra-args pass -> fd

KEYBINDINGS:
    ctrl-s horizontal direction splitw
    ctrl-v vertical direction splitw
    ctrl-o fzf-tmux-menu splitw
    alt-e subshell editor
    alt-enter open dirname file

```

它拥有以下特性：

1. 能够解析`fd` 几个比较实用的选项
2. 可以直接传递目录或文件（不需要添加其他符号）
3. 尽可能解释用户传入的选项，传参很方便(需要加`--split` )

```bash
# 解析顺序如下
__split() {
    while read -d " " -r entry; do
        # echo "|$entry|"
        # 1 解释为目录和文件
        __split_directory_or_file && continue
        # 2 解释为最大和最小深度
        [[ $flag_split -eq 1 || " $flag_split " == *" depth "* ]] && __split_depth && continue
        # 3 解释为文件类型
        [[ $flag_split -eq 1 || " $flag_split " == *" type "* ]] && __split_type && continue
        # 4 解释为文件类型和深度
        [[ $flag_split -eq 1 || " $flag_split " == *" depth_and_type "* ]] && __split_depth_and_type && continue
        # 5 解释为时间
        [[ $flag_split -eq 1 || " $flag_split " == *" changed_time "* ]] && __split_changed_time && continue
        # 6 解释为文件拓展名
        [[ $flag_split -eq 1 || " $flag_split " == *" extension "* ]] && __split_extension && continue
        # 7 解释为正则或通配模式
        [[ $flag_split -eq 1 || " $flag_split " == *" pattern "* ]] && __split_pattern || exit 1
    done <&0
}
# 接下来逐个示范
# 1 目录或文件 /只是为了区分目录，实际可以不写
cmd  fzf/ tools/toml
# 2 解释为最大和最小深度
cmd 1,10 # min-depth 1 max-depth 10
# 3 解释为文件类型
cmd xdf # x 可执行 d 目录 f 普通文件，没有其他标志了，防止冲突
# 4 解释为文件类型和最大深度
cmd 2x # max-depth=2 file-typ=x
# 5 解释为时间
cmd 1m | 1h | 1day[s] | 1w | 1M | 1y # 分时天周月年
# 6 解释为文件拓展名
cmd cc,py, # 以,结尾，
# 7 解释为正则或通配模式
cmd '\bfind\b'
cmd -g find*
# 8 如果文件或目录与其他模式冲突可以加 -q ，强制匹配的指定数量的文件名或目录参与其他匹配
:ls -> dx find ..
cmd dx find ... # 冲突 因为dx 和 find 是文件名，不会参与其他匹配
cmd dx find ... -q2 # 将前两个匹配的文件名用作其他模式
```

## search-string

> 交互式查找字符串

```bash
usage: ss [OPTIONS] [pattern] [DIRECTORIES or Files]

    OPTIONS:
        -t file types,  Comma-separated
        -T file types(not),  Comma-separated
        -d int max-depth
        -H bool --hidden
        -I bool --no-ignore
        -q Cancel the first n matching file names (Optional, default 1)
        -w world regex
        -u[uu] (Optional default -u)
        -O output to stdout
        -P no-popup
        -F full-window

        --help
        --split Explain the parameters passed in by the user as much as possible \
            priority: file_or_directory > max_depth > type > pattern (Optional default all)
        --extra-args pass -> fd

    KEYBINDINGS:
        ctrl-s horizontal direction splitw
        ctrl-v vertical direction splitw
        ctrl-o fzf-tmux-menu splitw
        alt-e subshell editor
        alt-enter open dirname file
```

它拥有以下特性：

1.  能够解析常用的参数
2.  接受目录或文件
3.  同find-files，尽可能解释用户传入的参数

参数的具体解析和find-files类似, 只不过它的选项比较少

```bash
__split() {
    while read -d " " -r entry; do
        # echo "|$entry|"
        # 1 解释为目录和文件
        __split_directory_or_file && continue
        # 2 解释为最大和最小深度
        [[ $flag_split -eq 1 || " $flag_split " == *" depth "* ]] && __split_max_depth && continue
        # 3 解释为文件类型
        [[ $flag_split -eq 1 || " $flag_split " == *" type "* ]] && __split_type && continue
        # 4 解释为正则或通配模式
        [[ $flag_split -eq 1 || " $flag_split " == *" pattern "* ]] && __split_pattern || exit 1
    done <&0

}
# 1 解释为目录和文件
# 2 解释为最大深度
# 3 解释为文件类型
cmd py,cpp, # rg --type=cpp --type=py
cmd ,c # rg --type-not=c
# 4 解释为正则或通配模式 同上
```

4.  能够在fzf过滤时，解释--iglob --hidden --no-ignore [[:digit:]] => max-depth
5.  **解决了\b的转义问题**

我怀疑`transform`执行代码是类似`eval`做多次解析的。
所以只要是在`transform`对查询字符串做处理，就永远无法解决`'\b'`字符的转义问题，因为它总是会被解释为`\b ->b`。
因此，我们把对字符串的分离放到文件中进行，借助`transform-query`传递命令而非字符串 。

```bash
transform_change="
setopt extended_glob
typeset args
[[ \$FZF_QUERY == *--* ]] && for elem in \${(s/ /)\${FZF_QUERY##*--}}; do
    case \$elem in
        H) args+=\\\"--hidden \\\" ;;
        I) args+=\\\"--no-ignore \\\" ;;
        [[:digit:]]) args+=\\\"--max-depth=\$elem \\\" ;;
        *) args+=\\\"'--iglob=\$elem' \\\" ;;
    esac
done
echo \\\"transform-query(echo -E \\\{q} > $file_pattern; sed 's/[[:blank:]]*--.*$//' $file_pattern)+reload(${cmd} \$args \\\{q} ${Directories} ${Files} || true)+transform-query(cat $file_pattern)\\\"
"
```

## fzf-filter

> 根据指定模式进行过滤，即以指定目录集作为源进行过滤。

```bash
fzf-filter zoxide # 以zoxide中的目录作为源过滤
fzf-filter git # 以所有git仓库的根目录作为源过滤

fzf-filter -P # 不popup
fzf-filter --before|--after <<<"aaaa\nbbbbb"  # 将标准输入附加到源前或源后同时过滤
```

对于marks,我关闭了它的在线过滤属性， 你会看到这么一句代码`if ((0)) && [[ $# -eq 0 ]]; then`, 因此它永远不会发生。
若要开启，请删除`((0)) &&`

它拥有良好的拓展性，你只需要在脚本中添加一个`__<mode>_mode` 函数，即可新增一种过滤模式。

## fzf-action

> 取代了directories-actions, 对fzf-filter筛选出的条目执行你想要的操作

# tmux

## fzf-tmux-menu

使用tmux菜单实现9种方式拆分,可以集成到上述脚本中使用
`top bottom left right fulltop fullbottom fullleft fullright new-window`

## session.sh

**支持以下功能**：

1. 附加到现有的非当前会话
2. 从zoxide或其他目录源(目前没有实现其他目录源)中选择一个目录作为会话的起始目录，会话名命名规则如下：

- 如果是家目录为前缀，`name=~<second to last directory>-<last directory>`
- 否则就是根目录前缀，`name=/<second to last directory>-<last directory>`
- 考虑到了只有一个目录的情况

3. 支持以查询字符串作为会话名创建(可以使用`alt-enter`准确无误触发，而`enter`只有当条目为0时才会触发 )。
4. 如果只有一个参数`-`，那么就会直接以当前目录创建会话。
5. 考虑受到搜索条目的影响，不能很好得打印查询字符串，定义`alt-enter`为`print-query`。同3。
6. 实现了tmux会话的基本预览效果。
   预览效果如下:

   ```bash
   1: bash* (2 panes) [159x42] [layout f8ef,159x42,0,0{82x42,0,0,1,76x42,83,0,2}] @1 (active)
    -> 1: [82x41] [history 78/50000, 281063 bytes] %1 (active)
    -> 2: [76x41] [history 294/50000, 338749 bytes] %2
   2: zsh- (2 panes) [159x42] [layout b7fa,159x42,0,0{79x42,0,0,23,79x42,80,0,24}] @22
    -> 1: [79x41] [history 11/50000, 26362 bytes] %23
    -> 2: [79x41] [history 8/50000, 13955 bytes] %24 (active)

   ```

7. 如何将它放到`tmux.conf`中快速触发使用呢？ 将下面的内容复制到`tmux.conf` 中即可。
   快捷键由前缀键触发，`TMUX_POPUP` 为了声明当前使用`tmux popup` 功能，使`session.sh`调用`fzf-filter`时传递`-P`参数，抑制`tmux`弹出。
   可以根据自己的实际，修改路径。
   ```tmux
   bind -N "create or switch session" o {
     popup -xC -yC -w70% -h80% -e TMUX_POPUP=1  -E "/home/mjj/.custom/scripts/tmux/session.sh"
   }
   ```

# tools

## toml

> 自己使用bash编写的一个用来解析toml文件的简单工具。

1. `-f` 指定解析文件的路径
2. `-t` 指定解析的哪一个表

例如：

```bash
# 在find-files脚本中使用函数封装解析toml文件的信息
toml() {
    toml_path="${CUSTOM_HOME}/scripts/tools/toml"
    config_dir="${CUSTOM_MARKS_FILE:-${XDG_CONFIG_HOME:-${HOME}/.config}/custom}"
    $toml_path "$1" -f "$config_dir/directories.toml" -t "marks" "${@:2}"
}
toml pmarks # 打印出对应文件对应表中定义的所有键
toml gmark "key" # 获取表中某一个键对应的值（只允许一个键，多个键可以写循环，尽量使功能单一化，方便调用和维护）

# 目前支持解析的形式（也只用到这么多）

key = "val"
key = [ "val1", "val2" ]
key = [
    "val1",
    "val2",
]
```

# 注意

## 1 变量

1. 目录标志定义的优先级为`$CUSTOM_MARKS_FILE > $XDG_CONFIG_HOME/custom/directories.toml > $HOME/.config/custom/directories.toml` 中。
   具体为：`${CUSTOM_MARKS_FILE:-${XDG_CONFIG_HOME:-${HOME}/.config}/custom/directories.toml}`
2. `CUSTOM_HOME` ，其中 fzf脚本位于`$CUSTOM_HOME/scripts/fzf` tmux脚本位于`$CUSTOM_HOME/scripts/tmux`。
   如果需要直接修改脚本`exec_action`函数即可

## 2 fzf

1. 非特殊情况，都是使用`--exact`标志进行精确匹配（匹配效果好）
2. 文件路径都使用`--tiebreak end,chunk,index`，在进行交互时，从后往前开始输入。
3. 文件路径都使用`--scheme path`，find-oldfiles除外。
4. 通过提供`FZF_TMUX_OPTS` 和 `fzf-tmux` 来使用tmux弹出窗口查询
5. fzf的版本不得低于0.46.1，如何执行失败请使用更高版本。
6. fzf过滤模式下，获取与最后一个文件名的最优匹配（而不是fullpath）,拥有更好的匹配度

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

# 我认为好用的

## aliases

```bash
vi="f() {${EDITOR} \${*:-.}; }; f" # vi会直接打开当前目录，而不是一个未命名的缓冲区。

```

## zoxide

重写了`__zoxide_z`和`__zoxide_zi`, 和往常一样使用即可。

```bash
## zxoide
function __zoxide_filter() {
  if [[ $# -eq 0 ]]; then
    echo "cat"
  else
    echo "fzf --filter \"${*}\" --exact --scheme history --tiebreak \"end,chunk,index\""
  fi
}
function __zoxide_z() {
    # shellcheck disable=SC2199
    if [[ "$#" -eq 0 ]]; then
        __zoxide_cd ~
    elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]$ ]]; }; then
        __zoxide_cd "$1"
    else
        # set -x
        builtin local result
        # shellcheck disable=SC2312
        result="$(command zoxide query --exclude "$(__zoxide_pwd)" --list |
            eval "$(__zoxide_filter $@)" | sed -n '1p')" && __zoxide_cd "${result}"
    fi
}
# Jump to a directory using interactive search.
function __zoxide_zi() {
    [[ -v TMUX ]] && command -v fzf-tmux &> /dev/null && fzf_bin=(fzf-tmux $FZF_TMUX_OPTS)
    builtin local result
    # set -x
    result="$(command zoxide query --exclude "$(__zoxide_pwd)" --list | eval "$(__zoxide_filter $@)" |
        lscolors | ${fzf_bin[*]:-fzf} +m \
            --exact --scheme history \
            --delimiter / --nth -1,-2,-3 \
    )" && __zoxide_cd "${result}"
}
```
