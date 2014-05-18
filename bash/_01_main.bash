
# Misc
# -----------------------------------------------------------------------------
alias resolution='xrandr -q | grep "*" | cut -d " " -f 4'
alias l='ls -lhaF --color=always'
alias git='LANG=en_US git'
alias gitlog="git log --oneline --graph --decorate"
# Cherche les fichier en double (taille puis md5)
alias doublons='find -not -empty -type f -printf "%s\n" | sort -rn | uniq -d | xargs -I{} -n1 find -type f -size {}c -print0 | xargs -0 md5sum | sort | uniq -w32 --all-repeated=separate'
alias process='ps aux | grep'

# Vim
# -----------------------------------------------------------------------------
export EDITOR=vim
alias vi='vim'
alias vi_sec="vim -u $HOME/.vim/.vimrc_secure"

# Navigation
# -----------------------------------------------------------------------------
alias dot="cd $DOTFILES_PATH"
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'

# Pass
# -----------------------------------------------------------------------------
alias pass="vi_sec $DOTFILES_PATH/.pass" # Crypt
# alias pass_generate="< /dev/urandom tr -dc A-Za-z0-9_ | head -c15"
pass_generate () {
	local lenght=$1
	[ "$lenght" == "" ] && lenght=16
	# tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${lenght} | xargs
	local password=$(tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${lenght})
	echo "$password"

	if [ -f /usr/bin/xclip ]; then
		echo $password | tr -d '\n' | xclip -i -selection clipboard
		echo "Password copied to clipboard"
	else
		echo "You should install xclip"
	fi
}

# Quick search in a directory for a string ($1).
# -----------------------------------------------------------------------------
search () {
	if [ -x /usr/bin/ack-grep ]; then
		ack-grep $1 .
	else
		grep -rnI --exclude-dir=dir --color=always $1 .
	fi
}

# Extract a package without pain
# -----------------------------------------------------------------------------
extract () {
	if [ -f $1 ]; then
		case $1 in
			(*.7z) 7z x $1 ;;
			(*.lzma) unlzma $1 ;;
			(*.rar) unrar x $1 ;;
			(*.tar) tar xvf $1 ;;
			(*.tar.bz2) tar xvjf $1 ;;
			(*.bz2) bunzip2 $1 ;;
			(*.tar.gz) tar xvzf $1 ;;
			(*.gz) gunzip $1 ;;
			(*.tar.xz) tar Jxvf $1 ;;
			(*.xz) xz -d $1 ;;
			(*.tbz2) tar xvjf $1 ;;
			(*.tgz) tar xvzf $1 ;;
			(*.zip) unzip $1 ;;
			(*.Z) uncompress ;;
			(*) echo "don't know how to extract '$1'..." ;;
		esac
	else
		echo "Error: '$1' is not a valid file!"
	fi
}

# Make a file backup
# -----------------------------------------------------------------------------
save () {
	cp $1 ${1}-`date +%Y%m%d%H%M`.bak ;
}

# Die motherfucker !
# -----------------------------------------------------------------------------
killbill () {
	BAK=$IFS
	IFS=$'\n'
	for id in $(ps aux | grep -P -i $1 | grep -v "grep" | awk '{printf $2" "; for (i=11; i<NF; i++) printf $i" "; print $NF}'); do
		service=$(echo $id | cut -d " " -f 1)
		if [[ $2 == "-t" ]]; then
			echo $service \"$(echo $id | cut -d " " -f 2-)\" "would be killed"
		else

			echo $service \"$(echo $id | cut -d " " -f 2-)\" "killed"
			kill -9 $service
		fi
	done
	IFS=$BAK
}
