## SVN Folder Upgrade

If you have a very old SVN checkout, you might need to upgrade it before SVN can be used via `svn upgrade`. This utility searches your VVV `/srv/www` folder for svn checkouts that need upgrading, and will search 5 folders down.

If you don't use `svn` this isn't very useful. This code used to be in VVV itself but was moved here in v3.5.

To use this, add it to the core utility in `config/config.yml`, then reprovision:

```yaml
utilities:
  core: # The core VVV utility
    - svn-folder-upgrade
... etc
```
