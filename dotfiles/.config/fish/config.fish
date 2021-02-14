alias ls='exa'
alias caldav='vdirsyncer sync && khal interactive && vdirsyncer sync && true'
alias mail='tmux new-session ";" source-file ~/.mutt/mail.tmux'
set PATH $PATH ~/.local/bin
set TERM xterm-256color
set -x GTK_THEME Adwaita:dark
set -x XDG_CURRENT_DESKTOP sway
function fish_greeting
  status --is-login
  if [ $status != 0 ] 
	neofetch --title_fqdn on
  end
end

