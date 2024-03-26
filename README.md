# 1 nvim 

1. man 查看man手册
2. fd-files 查找文件
3. fd-marks 查看预先定义目录别名的文件
4. fd-recent-nvim 查找最近被nvim打开的文件
6. rg 内容文件查找 （添加 --iglob 实时匹配 多正则表达式连接 可使用变量更改行为）
7. rg-recent-nvim 基于fd-recent-nvim文件，实行查找
8. rg-recent-all 基于fd-recent-all文件，实行查找

## fd 

`fd-files` `fd-marks` 支持部分自定义参数 `-fdlx -mnt` 

1. `-f` 文件
2. `-d` 目录
3. `-l` 软链接
4. `-x` 可执行文件
5. `-m \d` 查找最大深度
6. `-n \d` 查找最小深度
7. `-t (1min|1h|1day|2weeks)` 最近时间changed 

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


# 2 fzf
1. fzf-tmux-menu 使用tmux菜单实现9种方式拆分,可以集成到上述脚本中使用
    `top bottom left right fulltop fullbottom fullleft fullright new-window`
