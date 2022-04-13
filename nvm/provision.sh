#!/usr/bin/env bash
#
# NVM install to facilitate multiple versions of Nodejs
# Makes it easier to install new versions of Nodejs and
# to work with multiple projects that need different
# versions of Nodejs

echo " * Checking for NVM"

export NVM_DIR="/home/vagrant/.nvm"

echo " !! NVM is a part of VVV core as of v3.9, you should remove nvm from your extensions in config.yml !!"

if [[ -d "${NVM_DIR}" && -f "${NVM_DIR}/nvm.sh" ]]
then
  echo " ✓ NVM is already installed, checking for updates"
  (
    cd "$NVM_DIR"
    noroot git fetch --tags origin
    noroot git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
  ) && \. "$NVM_DIR/nvm.sh"
else
  if [[ -d "${NVMFOLDER}" && ! -f "${NVMFOLDER}/nvm.sh" ]]
  then
    # Possible remnants or something messed
    # up NVM install making it unusable
    echo " * NVM found in an unusable state, removing it completely"
    rm -rf "${NVM_DIR}"
  fi

  echo " * Installing NVM via git"
  (
    noroot git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    cd "${NVM_DIR}"
    noroot git checkout `noroot git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
  ) && \. "$NVM_DIR/nvm.sh"
  echo " ✓ NVM installed"

  echo 'export NVM_DIR="$HOME/.nvm"' >> /home/vagrant/.bashrc
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm' >> /home/vagrant/.bashrc
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> /home/vagrant/.bashrc
fi
