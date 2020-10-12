#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if ! [ -x "$(command -v dot)" ]; then

	apt_package_install_list=(
		graphviz
	)

	# Install required packages
	echo " * Installing graphviz apt-get packages..."
	if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken ${apt_package_install_list[@]}; then
		echo " * Installing apt-get packages returned a failure code, cleaning up apt caches then exiting"
		apt-get clean
		return 1
	fi

	echo " * symlinking dot"
	ln -sf "/usr/bin/dot" "/usr/local/bin/dot"

	echo " * graphviz provisioned"
else
	echo " * graphviz already installed"
fi
