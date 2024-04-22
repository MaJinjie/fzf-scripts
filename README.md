1. ff ./fzf/find-files 查找文件
2. ss ./fzf/search-string 搜索文本

# install

`git clone https://github.com/MaJinjie/fzf-scripts.git $CUSTOM_HOME/scripts`

# usage

## 1 aliases

```bash
ff "$CUSTOM_HOME/scripts/fzf/find-files -H -d6 --split --extra-args=\"-j 2\""
ss "$CUSTOM_HOME/scripts/fzf/search-string -F -d6 --split --extra-args=\"-j 4\""
frm "$CUSTOM_HOME/scripts/fzf/utils.sh rm --cmd=\"rm -rv\""
fcp "$CUSTOM_HOME/scripts/fzf/utils.sh cp --cmd=\"cp --backup=numbered -rv\""
fmv "$CUSTOM_HOME/scripts/fzf/utils.sh mv --cmd=\"mv --backup=numbered -v\""
```

## 2 PATH

> add to env PATH

# introduce

## find-files

> 最核心的两个脚本之一

```bash
# 1. 能够解析常用的参数
# 2. 接受目录或文件
# 3. 尽可能地解释用户传入的参数(很完美，几乎完全避免了和文件名或模式冲突)
#   1. depth: 1,10 depth[1,10] 1h,1dchanged-time[1h,1d]
#   2. time: 1d,1h [1d,1h] 2024-04-20,2024-04-25
#   3. extensions: cc,py. => .cc files
#   4. types: +x +i +h +Hx
#   5. , 去除所有的depth标志
usage: ff [OPTIONS] [DIRECTORIES or Files]

OPTIONS:
        -g glob-based search
        -p full-path
        -t char set, file types dfxlspebc (-t t...)
        -T string, changed after time ( 1min 1h 1d(default) 2weeks "2018-10-27 10:00:00" 2018-10-27)
        -d int, max-depth
        -H bool, --hidden
        -I bool, --no-ignore
        -P no-popup
        -F full-window
        -e extensions
        -E exclude glob pattern
        -O output to stdout
        -q Cancel the first n matching file names (Optional default 1)

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
        # 解释为文件类型
        [[ $flag_split -eq 1 || " $flag_split " == *" types "* ]] && __split_types && continue
        # 解释为拓展名
        [[ $flag_split -eq 1 || " $flag_split " == *" extensions "* ]] && __split_extensions && continue
        # 解释为目录的深度区间
        [[ $flag_split -eq 1 || " $flag_split " == *" depth_interval "* ]] && __split_depth_interval && continue
        # 解释为时间线的区间
        [[ $flag_split -eq 1 || " $flag_split " == *" time_interval "* ]] && __split_time_interval && continue
        # 解释为正则或通配模式
        [[ $flag_split -eq 1 || " $flag_split " == *" pattern "* ]] && __split_pattern || exit 1
    done <&0
}
# 接下来逐个示范 (有的叠加有的覆盖)
# 1 目录或文件 /只是为了区分目录，实际可以不写
cmd  fzf/ tools/toml
# 2 解释为类型(xdflspecbihIH) I => no-ignore  H => hidden h => clear hidden
cmd +xd
# 3 解释为深度范围
cmd 1,10
# 4 解释为时间线区间
cmd 1d,1h # 1day前 - 1h前修改的文件
cmd 2024-04-20,2024-04-25 # 20-25日修改的文件
# 5 解释为文件拓展名
cmd cc,py. # 以.结尾,以，分割
# 7 解释为正则或通配模式
cmd '\bfind\b'
cmd -g find*
# 8 如果文件或目录与其他模式冲突可以加 -q ，强制匹配的指定数量的文件名或目录参与其他匹配
:ls -> dx find ..
cmd +dx find ... # 冲突 因为dx 和 find 是文件名，不会参与其他匹配
cmd +dx find ... -q2 # 将前两个匹配的文件名用作其他模式
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

1. 能够解析常用的参数
2. 接受目录或文件
3. 尽可能解释用户传入的参数
   - ,10 max-depth=10
   - cpp. --type=cpp cc! --type-not=c
   - , 去除所有的depth标志
4. 能够正确解析带有空格的文件

```bash
__split() {
    while read -d " " -r entry; do
        # echo "|$entry|"
        # 解释为目录和文件
        __split_directory_or_file && continue
        # 解释为文件类型
        [[ $flag_split -eq 1 || " $flag_split " == *" types "* ]] && __split_types && continue
        [[ $flag_split -eq 1 || " $flag_split " == *" not_types "* ]] && __split_not_types && continue
        # 解释为目录的深度区间
        [[ $flag_split -eq 1 || " $flag_split " == *" depth_interval "* ]] && __split_depth_interval && continue
        # 解释为正则或通配模式
        [[ $flag_split -eq 1 || " $flag_split " == *" pattern "* ]] && __split_pattern || exit 1
    done <&0

}
# 1 解释为目录和文件
# 2 解释为最大深度
# 3 解释为文件类型
cmd py,cpp. # rg --type=cpp --type=py
cmd ,c! # rg --type-not=c
# 4 解释为正则或通配模式 同上
```

4.  能够在fzf过滤时，解释--iglob --hidden --no-ignore --max-depth(通用模式表达为`<1->`,正整数 )
5.  **解决了\b的转义问题**, 修复了输入时的多个bug。

    - 我怀疑`transform`执行代码是类似`eval`做多次解析的。
      所以只要是在`transform`中对查询字符串做处理，就永远无法解决`'\b'`字符的转义问题，因为它总是会被解释为`\b ->b`。
      因此，我们把对字符串的分离放到文件中进行，借助`transform-query`传递命令而非字符串 。
    - 无论是zsh的`print`命令还是bash的`echo`命令，对于单个`-`, 都是输出为空，需要使用`printf`
    - fzf和rg之间查询的切换做了非转义处理

```bash
transform_change="
    setopt extended_glob
    typeset args
    [[ \$FZF_QUERY == *--* ]] && for elem in \${(s/ /)\${FZF_QUERY##*--}}; do
        case \$elem in
            H) args+=\\\"--hidden \\\" ;;
            I) args+=\\\"--no-ignore \\\" ;;
            <1->) args+=\\\"--max-depth=\$elem \\\" ;;
            *) args+=\\\"'--iglob=\$elem' \\\" ;;
        esac
    done
    echo \\\"transform-query(printf %s \\\{q} > $file_pattern; sed 's/[[:blank:]]*--.*$//' $file_pattern)+reload(${cmd} \$args -- \\\{q} ${Directories} ${Files} || true)+transform-query(cat $file_pattern)\\\"
"

# 在没有给定初始匹配模式时，不会启动rg, 只有当Pattern不为空时才会启动初始查询。
init_bind="
--query '$Pattern'
--bind=\"start:reload:${cmd} -- \{q} ${Directories} ${Files}\"
"
```

## fzf/utils.sh

> 基于find-files脚本，为常用命令编写的实用工具。

**目前包含以下几个命令：**

1. `rm` 选择 + 删除，默认命令`rm -r`
2. `cp` 指定目录 + 选择 + 拷贝，默认命令`cp -a`
3. `mv` 指定目录 + 选择 + 移动，默认命令`mv --backup=numbered`

详细参数请看脚本中的参数解析

## tmux/fzf-tmux-menu

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

## tools/toml

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
toml gmark "key" # 获取表中某一个键对应的值（只允许一个键，多个键可以写循环）

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
