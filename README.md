# VVV Utilities

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/11a6ce9836224f1781d17918d0e0d605)](https://www.codacy.com/gh/Varying-Vagrant-Vagrants/vvv-utilities?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=Varying-Vagrant-Vagrants/vvv-utilities&amp;utm_campaign=Badge_Grade)

These are optional system level features and software for [VVV](https://github.com/varying-vagrant-vagrants/vvv/), we call them utilities. This repo is the `core` utility, and has a continuous release process, all version of VVV use this git repo.

Here is how you might use this utility to install software in `config/config.yml`:

```yaml
utilities:
  core: # The core VVV utility
    - tls-ca # HTTPS SSL/TLS certificates
    - phpmyadmin # Web based database client
    - php73
```

Each item is the name of a folder, in the above example, adding `php73` means that VVV will run the `php73/provision.sh` script when provisioning. Likewise if you added a `banana/provision.sh` and listed ` - banana` in `config/config.yml`, then `banana/provision.sh` would run on the next provision.

For more information about utilities and how to create your own, [read our utilities chapter on the documentation site](https://varyingvagrantvagrants.org/docs/en-US/utilities/)
