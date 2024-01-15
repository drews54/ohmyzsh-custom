if [[ -n $SSH_CONNECTION ]]
then
	alias ls=lsd
else
	alias ls='lsd --icon=never'
fi
alias cat='bat -p'
alias ffmpeg='ffmpeg -hide_banner'
alias ffplay='ffplay -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias icat='kitten icat'
alias kd='kitten diff'
alias ktd='kitten transfer --confirm-paths --transmit-deltas --direction=download'
alias ktu='kitten transfer --confirm-paths --transmit-deltas --direction=upload'
alias rm='rm -I'
alias se=sudoedit
alias sv='sudo vim'
alias v=vim
alias watch=viddy
alias yt-dlp='yt-dlp --downloader aria2c'
