export EDITOR=nvim
export GPG_TTY=$(tty)
export LC_ALL=ru_RU.UTF-8
export MONO_GAC_PREFIX="/opt/homebrew"
export HISTIGNORE='*sudo -S*'
[[ -v XDG_DATA_DIRS ]] && export XDG_DATA_DIRS="/opt/homebrew/share:$XDG_DATA_DIRS" || export XDG_DATA_DIRS="/opt/homebrew/share"
export HOMEBREW_NO_ENV_HINTS=true
export HOMEBREW_UPGRADE_GREEDY=true
