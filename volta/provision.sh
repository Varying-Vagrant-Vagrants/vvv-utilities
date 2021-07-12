#!/usr/bin/env bash
#
# The Hassle-Free JavaScript Tool Manager
# https://volta.sh/
# Makes it easier to install new versions of Nodejs and
# to work with multiple projects that need different
# versions of Nodejs

echo " * Checking for Volta"

if [[ -d ~/.volta ]]
then
  echo " ✓ Volta is already installed, no need to install again"
else
  # lets install it now
  echo " * Downloading and running Volta installation."
  noroot curl https://get.volta.sh | bash
  echo " ✓ Volta installed."
fi
