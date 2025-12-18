if [[ -n $SSH_CONNECTION ]]
then
	alias ls=lsd
	alias lst='ls --tree'
else
	alias ls='lsd --icon=never'
	alias lst='ls --tree'
fi
alias autoprimenet='autoprimenet -w$HOME/autoprimenet'
alias cat='bat -p'
alias ffmpeg='ffmpeg -hide_banner'
alias ffplay='ffplay -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias icat='kitten icat'
alias kd='kitten diff'
alias ktd='kitten transfer --confirm-paths --transmit-deltas --direction=download'
alias ktu='kitten transfer --confirm-paths --transmit-deltas --direction=upload'
alias mprime='sudo mprime -w/var/opt/mprime'
alias ntfy-srv='ntfy publish server_notifications'
alias rm='rm -I'
alias se=sudoedit
alias sv='sudo vim'
alias v=vim
alias watch=viddy
alias webm_to_hvc1='to_hvc1 -fa *.webm && ntfy pub server_notifications Videos converted successfully'
alias yt-dlp='yt-dlp --downloader aria2c'
