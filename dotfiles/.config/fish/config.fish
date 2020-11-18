alias ls='exa'
alias caldav='vdirsyncer sync && khal interactive && vdirsyncer sync && true'
set TERM xterm-256color
function fish_greeting
  status --is-login
  if [ $status != 0 ] 
	neofetch --title_fqdn on
  end
end

