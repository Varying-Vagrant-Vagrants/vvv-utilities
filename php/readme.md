# All PHP Versions Extension

## What Does it Do?
This extension installs every PHP version available. It saves typing out `php81` and `php82` etc etc in `config.yml` or having to add new entries when new versions come out.

This does mean though that provisioning will take longer as it installs _all_ the versions which takes time.

## How Do I Remove or Exclude a Version?

You don't/can't.

Warning: Removing this won't uninstall those versions, extensions add things, they don't remove them.

If you used this and no longer need the other PHP versions, you'd have to:

1. Back up your databases.
2. Destroy the VVV instance with `vagrant destroy`.
3. Remove this extension from `config.yml`.
4. Then recreate your VVV instance.
5. Restore the database back ups you made.

## How to Modify PHP Configs

**TLDR: Don't modify the php.ini for a version, add your own ini files!**

Each version has its own folder and you might be tempted ot modify the `php.ini` but this is a mistake! Now the extensions won't update and your changes might get overwritten on provision!

Add your own `.ini` file to the folders with a new name and it will be included without causing issues.
