# 1 nvim 

1. man 查看man手册
2. fd 查找文件
3. fd-recent-nvim 查找最近被nvim打开的文件
4. rg 内容文件查找 （添加 --iglob 实时匹配 多正则表达式连接 可使用变量更改行为）
5. rg-recent-nvim 基于fd-recent-nvim文件，实行查找

## fd 

`fd` 支持部分自定义参数 具体说明见 `fd help` 

目前支持三点:
1. 部分自定义参数：-t(changed-after) -d(dir) -f(regular files) -x(exec files) -D(max-depth) -h(no hidden) -g(git ls-files) -n(no-ignore)
2. 可以传入指定相对或绝对目录
3. `--` 后可加入目录标签 
    (`typeset -A marks=([nv]=$HOME/.config/nvim)` `fd -- nv` 相当于 `fd -- ${marks[nv]} `   )


**两种查找模式**
1. fd 普通查找(可以查找最近文件)，使用fd命令,除了-g,其他参数都可用 --也可用
2. 查找当前git库文件，除了-g,其他参数不可用, 如果指定了目录，则查找指定目录的git文件

## rg 
> 对rg的工作解释

改良（使用while 循环遍历）
1. 使用 -- 来声明 iglob通配符表达式,可以有多个, 可以在任意位置
2. 使用 & 来连接多个正则表达式，实现类似连续模糊查找的效果,可以在任意位置
（对于单个正则，它的效果和原来相同, 内部使用.*来连接）
（多个连续的&没有效果（符合逻辑）)
3. 尝试解决\b在bash和正则之间的冲突，可惜没有成功。`\b` 需要键入`\\b`,其他如常
4. 使用 REGEX_SEPARATE IGLOB_SEPARATE CONNECT_REGEX 变量代替字面量
例如 `^env & cb &cd => ^env.*cb.*cd`
     `-- *ab* *fd* -- a* => --iglob *ab* *fd* a*`
     `-- *fd* & ^fd -- *rg*&cd => --iglob *fd* *rg*    ^fd.*cd`


如有需要可添加：-- 可以识别 `H F D[\d] ...` 展开为 `--hidden --follow --max-depth=\d ...` 
例如 `-- *fd* H *rg* D4 => --iglob *fd* --iglob *rg* --hidden --max-depth=4`
只需要添加一个case即可

那些参数看`rg help`
**三种查找模式**
1. 普通查找 可以-h -D -n 可用，在线的iglob和regex可用
2. 最近文件查找，fd + rg， -h -D -n -x -t 都是 fd命令使用。该模式由-t参数触发
3. git文件内容查找， 除了-g参数，其他参数不可用。如果指定了目录，则查找指定目录的git文件

注意：`-t -g` 都是可选值参数，当不提供值时，`-t 1d` `-g git ls-files` 
# 2 fzf
1. fzf-tmux-menu 使用tmux菜单实现9种方式拆分,可以集成到上述脚本中使用
    `top bottom left right fulltop fullbottom fullleft fullright new-window`
