#!/bin/bash
AUR_PATH=~/.aur
BASE_GIT_CLONE_URL=https://aur.archlinux.org/

install_loop() {
	for package_name in "${@:1}"; do
        if pacman -Qs $package_name > /dev/null; then
		  echo "The package $package_name is already installed"
		  continue
		fi

		if [ -d "$AUR_PATH/$package_name" ]; then
			rm -rf "$AUR_PATH/$package_name"
		fi

		if [[ ! $(git ls-remote $BASE_GIT_CLONE_URL$package_name.git) ]]; then
			echo "Can't find git repository $BASE_GIT_CLONE_URL$package_name.git; package name $package_name may be incorrect; exit"
			exit 1
		fi	

		cd $AUR_PATH
		git clone $BASE_GIT_CLONE_URL$package_name.git &&
		if [ -d $package_name ]; then
			cd $package_name

			check_missing_pgp_keys

			try_makepkg_install_clean
		fi
	done
}

try_makepkg_install_clean() {
	if ! makepkg -sic; then
		git clean -fd
		rm -rf "$AUR_PATH/$package_name"
		exit 1
	else
		git clean -fd
	fi		
}

check_missing_pgp_keys() {
	for pgpkey in $(grep -o '\validpgpkeys.*' .SRCINFO); do
		if [ "$pgpkey" = "validpgpkeys" ] || [ "$pgpkey" == "=" ]; then
			continue
		fi
		if ! gpg --list-keys $pgpkey > /dev/null 2>&1; then
			while true; do
				read -p "Import pgp key $pgpkey? (y/n) " yn
				case $yn in
					[yY]) 
						gpg --recv-keys $pgpkey
						break;;
					[nN]) 
						echo "Cancel import pgp key; package installation may fail"
						break;;
				esac
			done
		fi
	done
}

check_empty_install_argument() {
	if [ -z "$1" ]; then
        echo "Empty argument; try '--install Foo'"
        exit 1
	fi
}

check_create_aur_path_dir() {
	if [ ! -d $AUR_PATH ]; then
		if ! mkdir -p $AUR_PATH; then
			echo "can't create folder at path $AUR_PATH; exit"
			exit 1
		fi
	fi
}

check_empty_remove_argument() {
	if [ -z "$1" ]; then
      echo "Empty argument; try '--remove Foo'"
      exit 1
	fi
}

remove_loop() {
	for package_name in "${@:1}"; do		
		if pacman -Qi $package_name > /dev/null; then
			sudo pacman -Rns $package_name &&
			if [ -d "$AUR_PATH/$package_name" ]; then
				rm -rf "$AUR_PATH/$package_name"
			fi
	    else
			echo "The package $package_name is not installed, can't remove"
			continue
		fi
	done
}

set_has_update_count() {
	if [ -d "$AUR_PATH/" ] && [ -n "$(ls -A "$AUR_PATH/")" ]; then
		has_update_count=0

	    cd $AUR_PATH
	    for package_dir in */; do
			if ! pacman -Qs ${package_dir::-1} > /dev/null; then
				continue
			fi

	    	cd $AUR_PATH/$package_dir

			git checkout . > /dev/null 2>&1;

			git fetch
			if [ ! $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
				sed 's/\// /g') | cut -f1) ]; then
				((has_update_count++))
				echo "There is an update for ${package_dir::-1}"
			else
				echo "${package_dir::-1} is up to date"
			fi
	    done
	else    
		echo "$AUR_PATH is empty or not a folder; exit"
	    exit 1
    fi
}

confirm_upgrade() {
	while true; do
		read -p "$has_update_count updates available. Upgrade? (y/n) " yn
		case $yn in
			[yY] ) break;;
			[nN] ) exit 0;;
		esac
	done
}

upgrade_loop() {
	cd $AUR_PATH
	for package_dir in */; do
		if ! pacman -Qs ${package_dir::-1} > /dev/null; then
			continue
		fi

		cd $AUR_PATH/$package_dir
		if [ ! $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
			sed 's/\// /g') | cut -f1) ]; then
			check_missing_pgp_keys
			git pull &&
			makepkg -sic
			git clean -fd
		fi
	done
}

check_no_updates() {
	if [[ "$has_update_count" -eq 0 ]]; then
		echo "$has_update_count updates available"
		exit 0
	fi
}

case "$1" in
	"--install")
		check_empty_install_argument "${@:2}"
		check_create_aur_path_dir
		install_loop "${@:2}"
		exit 0;;
	"--remove")
		check_empty_remove_argument "${@:2}"
		remove_loop "${@:2}"
		exit 0;;
	"--upgrade")
		set_has_update_count
		check_no_updates
		confirm_upgrade
		upgrade_loop	
		exit 0;;
	*)
		echo "Invalid argument; try '--install Foo' or '--remove Foo' or '--upgrade'"
		exit 1;;
esac
