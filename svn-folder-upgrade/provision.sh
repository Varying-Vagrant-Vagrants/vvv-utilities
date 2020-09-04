#!/usr/bin/env bash

echo " * Running all PHP provisioners"

wpsvn_check() {
  # Get all SVN repos.
  svn_repos=$(find /srv/www -maxdepth 5 -type d -name '.svn');

  # Do we have any?
  if [[ -n $svn_repos ]]; then
    echo " * ${#svn_repos[@]} SVN repositories found, checking for upgrades..."
    for repo in $svn_repos; do
      # Test to see if an svn upgrade is needed on this repo.
      svn_test=$( svn status -u "$repo" 2>&1 );

      if [[ "$svn_test" == *"svn upgrade"* ]]; then
        # If it is needed do it!
        echo " * Upgrading SVN repository at: ${repo}"
        svn upgrade "${repo/%\.svn/}"
        echo " * SVN upgrade command finished in  ${repo}"
      fi;
    done
  fi;
}

echo " * Searching for SVN repositories that need upgrading."
wpsvn_check
echo " * SVN repository upgrade search has ended."
