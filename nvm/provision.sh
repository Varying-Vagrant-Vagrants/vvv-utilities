#!/usr/bin/env bash
#
# NVM install to facilitate multiple versions of Nodejs
# Makes it easier to install new versions of Nodejs and
# to work with multiple projects that need different
# versions of Nodejs

echo " * Checking for NVM"

if [[ -d ~/.nvm && -f ~/.nvm/nvm.sh ]]
then
  echo " * NVM is already installed, no need to install again"
else
  if [[ -d ~/.nvm && ! -f ~/.nvm/nvm.sh ]]
  then
    # Possible remnants or something messed
    # up NVM install making it unusable
    echo " * NVM found in an unusable state, removing it completely"
    rm -rf ~/.nvm
  fi

  # lets install it now
  echo " * NVM installation starting now"
  noroot curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
  noroot $HOME/.nvm/nvm.sh
  echo " * NVM installed"

  # set default node to the one installed by VVV
  nvm alias default system
  echo " * NVM default set to system default"
fi
