if [[ -n $SSH_CONNECTION ]]
then
	alias ls=lsd
else
	alias ls='lsd --icon=never'
fi
alias cat='bat -p'
alias download-mods='sudo -u blobbot curl -LOJ --output-dir /opt/container-data/minecraft-server/mods'
alias ffmpeg='ffmpeg -hide_banner'
alias ffplay='ffplay -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias icat="kitten icat"
alias rm='rm -I'
alias ktd='kitten transfer --confirm-paths --transmit-deltas --direction=download'
alias ktu='kitten transfer --confirm-paths --transmit-deltas --direction=upload'
alias yt-dlp='yt-dlp --downloader aria2c'
