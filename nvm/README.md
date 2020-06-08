# Node Version Manager

`nvm` is a version manager for [node.js](https://nodejs.org/en/), designed to be installed per-user, and invoked per-shell. `nvm` works on any POSIX-compliant shell (sh, dash, ksh, zsh, bash), in particular on these platforms: unix, macOS, and windows WSL.

See full documentation here: [https://github.com/nvm-sh/nvm](https://github.com/nvm-sh/nvm)

**This VVV utility will install `nvm` and set default version to the one that VVV installs.**

## Usage

To download, compile, and install the latest release of node, do this:

```bash
nvm install node # "node" is an alias for the latest version
```

You can list available versions using  `ls-remote`:

```bash
nvm ls-remote
```

To install a specific version of node:

```bash
nvm install 6.14.4 # or 10.10.0, 8.9.1, etc
```

If you want to see what versions are installed:

```bash
nvm ls
```
