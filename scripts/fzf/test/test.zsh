#!/bin/env zsh

# fd="fd "
# $fd
# file_cmd="printf %s\\\n $1 | lscolors"
#
# eval $file_cmd

setopt rematchpcre
set -x
# str="e/zsh,sh/f/hi/"
# [[ "$str" =~ ^[[:alpha:]]/.*?/ ]] && echo $MATCH

[[ $1 =~ '^(?:aa).*$' ]] && print $MATCH
# [[ $1 =~ '^\w' ]] && print $MATCH
