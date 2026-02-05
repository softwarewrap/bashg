#!/bin/zsh

#***********************************************************************#
#* ENVIRONMENT                                                         *#
#***********************************************************************#

export ENV_HOME=$HOME
export EDITOR=vi
export PAGER=less
export LESS="-X -F -R"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export DIRSTACKSIZE=20
export HISTSIZE=999999
export SAVEHIST=$HISTSIZE
export HISTFILE="$HOME"/.history
export HOST="$(/bin/hostname)"
export MAILCHECK=999999999
export LESSBINFMT='*u%x'
export READNULLCMD=less
export SHELL=/bin/zsh
export TAB=$'\011'
export TERM=xterm-256color
export QUOTING_STYLE=literal
export KEYTIMEOUT=1

setopt                        \
   AUTOMENU                   \
   EXTENDED_GLOB              \
   EXTENDED_HISTORY           \
   SHARE_HISTORY              \
   HIST_IGNORE_DUPS           \
   HIST_IGNORE_SPACE          \
   IGNOREEOF                  \
   INTERACTIVE_COMMENTS       \
   LIST_TYPES                 \
   NO_NOMATCH                 \
   NOTIFY                     \
   NULL_GLOB                  \
   NUMERICGLOBSORT            \
   PATH_DIRS                  \
   PUSHD_IGNORE_DUPS          \
   PUSHD_SILENT               \
   RM_STAR_SILENT             \
   SUN_KEYBOARD_HACK          \
   TYPESET_SILENT             \
   ZLE

unset zle_bracketed_paste
zle_highlight=('paste:none')
zstyle ':completion:*:*:cd:*' tag-order local-directories

setopt -m
bindkey -v
compctl -c man
compctl -v export printenv
fignore=(.o \~)

#***********************************************************************#
#* ALIASES                                                             *#
#***********************************************************************#

alias more=less
alias ..='. "$HOME"/.zshrc'
alias d='dirs -v'
alias h='fc -li'
alias D='docker'
alias l='bash-do :git:log'

#***********************************************************************#
#* FUNCTIONS                                                           *#
#***********************************************************************#

is()
{
   for FILE
   do
      alias "$FILE" || functions "$FILE" || path "$FILE" || type "$FILE"
   done
}

# Banner
setbanner()
{
   case "$1" in
   none)       BANNER="";;
   =)          BANNER=']2;'"${@:2} %a %b %e %l:%M:%S %p"''; print -Pn "$BANNER";;
   *|standard) BANNER=']2;'"[$(whoami)@$(hostname)]   %D{%a %b %e @ %l:%M:%S %p}"'' ;;
   esac
}

# Prompt
plimit()
{
    if [[ $1 = = ]] ; then
       if (( $# == 1 )) ; then
          export PATH_LIMIT=70
       else
          export PATH_LIMIT="$2"
       fi
    else
       if (( $# == 1 )) ; then
          export PATH_LIMIT="$1"
       fi
       echo "Path limit: $PATH_LIMIT"
    fi

    chpwd
}

vstart()
{
   __TopDir="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"

   if [[ $# -eq 0 && -n $__TopDir && -f $HOME/.venv/${__TopDir##*/}/bin/activate ]]; then
      source "$HOME/.venv/${__TopDir##*/}/bin/activate"

   elif [[ -f $HOME/.venv/$1/bin/activate ]]; then
      source "$HOME/.venv/$1/bin/activate"

   elif [[ -f /opt/venv/$1/bin/activate ]]; then
      source "/opt/venv/$1/bin/activate"

   else
      echo "Could not determine the python environment to activate"
      return
   fi

   chpwd
}

vstop()
{
   if command -v deactivate; then
      deactivate
   fi
}

vstatus() {
    if [[ -n $VIRTUAL_ENV ]]; then
        echo "Active virtual environment: ${VIRTUAL_ENV##*/}"
    else
        echo "No virtual environment active."
    fi
}

term_style_fancy()
{
    term_style=fancy
    PROMPT_VENV="${VIRTUAL_ENV##*/}"
    PROMPT="${PROMPT_VENV:+[}$PROMPT_VENV${PROMPT_VENV:+] }%S%D{%b %e %T} !%! [$(pfrag "$(print -P %~)"|sed 's|%|%%|g')$PROMPT_END%s
"
}

term_style_plain()
{
    term_style=plain
    PROMPT_VENV="${VIRTUAL_ENV##*/}"
    PROMPT="${PROMPT_VENV:+[}$PROMPT_VENV${PROMPT_VENV:+] }%D{%b %e %T} !%! [$(pfrag "$(print -P %~)"|sed 's|%|%%|g')$PROMPT_END
"
}

precmd()
{
    echo
    [[ -z $BANNER ]] || print -Pn "$BANNER"
}

chpwd ()
{
    if (( $# > 0 )); then
       term_style="$1"
    fi
    case "$term_style" in
       fancy ) term_style_fancy ;;
       * )     term_style_plain ;;
    esac
}

# Directory
push()
{
   local Options
   Options=$(getopt -o 'r' -l 'resolve' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$Options"

   local Resolve=false

   while true ; do
      case "$1" in
      -r|--resolve)  Resolve=true; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done
   $Resolve && pushd "$(readlink -fm "$1" )" || pushd "$1"
   d
}

pop()
{
   if [[ $1 = = ]]; then
      shift
      COUNT="$1"
      while (( $COUNT > 0 )); do
         popd
         COUNT=$(($COUNT - 1))
      done
   else
      popd $*
   fi
   d
}

r()
{
    if (( $# == 0 )); then
       push +1
    else
       push +$1
    fi
}

# addtag <name> <dir>  - sets tag <name> to <dir> and updates $HOME/.zshrc.d/tags.zsh
addtag()
{
   WriteTag=true
   if [[ $1 = -s ]]; then
      WriteTag=false
      shift
   fi

   eval export "$1"="$(readlink -f "${2:-.}")"

   if $WriteTag; then
      if [[ -f $HOME/.zshrc.d/tags.zsh ]]; then
         sed -i "/^tag $1 /d" "$HOME/.zshrc.d/tags.zsh"
      fi
      echo "tag -s $1 $2" >> "$HOME/.zshrc.d/tags.zsh"
   fi
}

# tag <name>        - set <name> as the tag for the present working directory (PWD)
# tag <name> <dir>  - set <name> as the tag for the given directory (<dir>)
# tag               - show all tags
tag()
{
   TagOption=
   if [[ $1 = -s ]]; then
      TagOption="-s"
      shift
   fi
   case $# in
   0) if [[ ! -f $HOME/.zshrc.d/tags.zsh ]]; then
         mkdir -p "$HOME"/.zshrc.d
         touch "$HOME"/.zshrc.d/tags.zsh
      fi
      cat "$HOME"/.zshrc.d/tags.zsh | expand -20;;
   1) addtag $TagOption "$1" "$PWD";;
   2) addtag $TagOption "$1" "$2";;
   esac
}

# rmtag <name>      - remove tag named <name> if it exists
rmtag()
{
   if [[ -n $1 ]]; then
      sed -i "/^tag $1 /d" "$HOME/.zshrc.d/tags.zsh"
      unset $1
   fi
}

# Fix for <ESC>/ being interpreted as <esc-/>
# See: https://superuser.com/questions/476532/how-can-i-make-zshs-vi-mode-behave-more-like-bashs-vi-mode
vi-search-fix()
{
   zle vi-cmd-mode
   zle .vi-history-search-backward
}
autoload vi-search-fix
zle -N vi-search-fix
bindkey -M viins '\e/' vi-search-fix

# FILES
export LS_COLORS='no=00:fi=00:di=01;34:ln=01:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=01:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.flac=01;35:*.mp3=01;35:*.mpc=01;35:*.ogg=01;35:*.wav=01;35:';
for Cmd in ls la ll lla lL; do
   unalias $Cmd &>/dev/null
   unfunction $Cmd &>/dev/null
done
ls()  { LC_ALL=C /bin/ls -FC --color=tty $@ }
la()  { LC_ALL=C /bin/ls -A --color=tty $@ }
ll()  { LC_ALL=C /bin/ls -l --color=tty $@ }
lla() { LC_ALL=C /bin/ls -lA --color=tty $@ }
lL()  { LC_ALL=C /bin/ls -LFl --color=tty $@ }
lf()  { if [[ $# -gt 0 ]]; then find "$@" -type f; else find . -type f; fi }

# UTILITY ROUTINES
addpath()
{
   local WHERE="$1"; shift
   local I
   if [[ $WHERE = before ]]; then
      for ((I=$#; I > 0; I--)); do
         pathmunge "${(P)I}" "$WHERE" remove add
      done
   else
      for ((I=1; I <= $#; I++)); do
         pathmunge "${(P)I}" "$WHERE" remove add
      done
   fi
}

addmanpath()
{
   local WHERE="$1"; shift
   local I
   if [[ $WHERE = before ]]; then
      for ((I=$#; I > 0; I--)); do
         manpathmunge "${(P)I}" "$WHERE" remove add
      done
   else
      for ((I=1; I <= $#; I++)); do
         manpathmunge "${(P)I}" "$WHERE" remove add
      done
   fi
}

#***********************************************************************#
#* SETUP                                                               *#
#***********************************************************************#
. /etc/profile.sh

cdpath=(.. $HOME)
addpath after /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin /bin /sbin
addpath before "$HOME/bin"
addmanpath before /usr/local/share/man /usr/share/locale/man /usr/share/man

[[ $(whoami) == root ]] && PROMPT_END="]#" || PROMPT_END="]"
plimit=
chpwd fancy
setbanner standard

noglob stty erase  kill ^u intr ^c werase  -tabs crt -tostop pass8

for ZshrcFile in "$HOME"/.zshrc.d/*.zsh; do
   . "$ZshrcFile"
done
