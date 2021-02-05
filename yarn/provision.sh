#!/usr/bin/env bash
#
# Yarn is a package manager that doubles down as project manager.
# Whether you work on one-shot projects or large monorepos, as
# a hobbyist or an enterprise user, we've got you covered.
#
# https://yarnpkg.com/

echo " * Checking for Yarn."
noroot npm install -g yarn
echo " ✓ Yarn installed."
