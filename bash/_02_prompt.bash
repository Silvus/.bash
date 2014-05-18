# Prompt
# --------------------------------------------------------------------------------------
_has_parent_dir () {
	# Utility function so we can test for things like .git/.hg without firing up a separate process
	test -d "$1" && return 0;

	current="."
	while [ ! "$current" -ef "$current/.." ]; do
		if [ -d "$current/$1" ]; then
			return 0;
		fi
		current="$current/..";
	done

	return 1;
}

_vcs_name () {
	if [ -d .svn ]; then
		echo "-[svn]";
	elif _has_parent_dir ".git"; then
		echo "-[$(__git_ps1 'git %s')]";
	elif _has_parent_dir ".hg"; then
		echo "-[hg $(hg branch)]"
	fi
}

# Colors
black=$(tput -Txterm setaf 0)
# red=$(tput -Txterm setaf 1)
green=$(tput -Txterm setaf 2)
yellow=$(tput -Txterm setaf 3)
dk_blue=$(tput -Txterm setaf 4)
pink=$(tput -Txterm setaf 5)
# lt_blue=$(tput -Txterm setaf 6)

# Styles
bold=$(tput -Txterm bold)
reset=$(tput -Txterm sgr0)

export PS1='\[$bold\]\[$black\][\[$dk_blue\]\D{%T}\[$black\]]-[\[$green\]\u\[$yellow\]@\[$green\]\h\[$black\]]-[\[$pink\]\w\[$black\]]\[\033[0;33m\]$(_vcs_name) \[\033[00m\]\[$reset\]\$ '
