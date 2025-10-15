> [!IMPORTANT]
> I am spread too thin between all of my projects, so if you can support my efforts or wish to contribute - please contact me.
>
> My username here is almost the same on most popular online social platforms.
>
> I am open to business proposals as well. CV at LinkedIn.

# Bash Utility Functions Library

A collection of pre-made commands reducing cognitive load on the user.

Can be useful for active `rpm-ostree`, `podman`, `distrobox` & `adb` users.

> [!NOTE]
> Intended for `source` (or `.`).

> [!WARNING]
> Use this code at your own risk, it was not well-tested!
>
> I am a solo developer with little resources so I can't guarantee smooth operation.
>
> I am writing these scripts to be stable to the best of my abilities and knowledge.

# Installation

> [!TIP]
> To keep your system de-cluttered, install scripts to a location shared between users.

> [!CAUTION]
> Be careful with elevated privileges execution and important system files editing!

## Pick a `scope_path`

| User scope    | For login sessions | For interactive sessions |
|---------------|--------------------|--------------------------|
| System-wide   | `/etc/profile.d/`  | `/etc/bashrc.d/`         |
| User-specific | `~/.profile.d/`    | `~/.bashrc.d/`           |

## Install

```sh
# sudo -i # if necessary, e.g. system-wide installation
# Download and source the install function script
curl -o /tmp/bash_utils.install.sh https://raw.githubusercontent.com/tsilvs/bash_utils/refs/heads/main/install.sh
source /tmp/bash_utils.install.sh
# call the function
scope_path="whatever/you/chose" bash_utils.install.clone "${scope_path}" git@github.com:tsilvs/bash_utils.git
# Add next line to the default sourced file (e.g. `/etc/bashrc`).
for f in "${scope_path}"/*.sh; do source $f; done
```

## Update

```sh
# sudo -i # if necessary, e.g. system-wide installation
# Pull an update with `git`
scope_path="whatever/you/chose" git_remote="origin" git -C "${scope_path}" pull "${git_remote}"
```

> [!TIP]
> You can also deploy your own `git` user and store ***bare repos*** locally

# Plans

+ [x] Better installation script
+ [ ] Rewrite with any `bash` scripting library (e.g. `aks/bash-lib`?) or pre-processor (e.g. `TypeShell`?) for better stability, reliability and maintainability
+ [ ] Programming language rewrite?
	+ [ ] Interpreted (TypeScript, PureScript)?
	+ [ ] Compiled (Zig, Rust, Crystal, Go, Kotlin, Haskell, Nim, F#, OCaml)?
	+ [ ] any other that's well integrated with Linux ecosystem?
+ [ ] Proper packaging with `.rpm`, `.deb`, `pkgbuild`, `flatpak`, `bpkg`, `podman` image or any other suitable packaging tool
+ [ ] UI with `yad`
+ [ ] Proper i18n with separate locale files