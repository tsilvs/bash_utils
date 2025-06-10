# Ostree Utils

# Terminology

# Deployment - a commit that's marked as a bootable version of the OS. Can be referred to by a numerical index (0++).
# Origin - repository available by an URL, description stored in an origin file
# Sysroot - "System Root", a physical location storing repo and deployments
# bootc - ?


# Typical file locations
# `/sysroot` - system root
# ├── boot
# ├── dev
# ├── home
# ├── ostree
# │   ├── boot.1 -> boot.1.1
# │   ├── boot.1.1
# │   │   └── default
# │   │       ├── 170de07ff6d625f54e4ad0e3958136b1cfa481093de0dbd27a6ab142ddd772d5
# │   │       └── 83b7b1437007bbebfb9fbdfd35bb3e0b90bb13bcfa7065a69afe441c676b44d7
# │   ├── deploy
# │   │   └── default
# │   │       ├── backing
# │   │       ├── deploy
# │   │       └── var
# │   └── repo
# │       ├── extensions
# │       │   └── rpmostree
# │       ├── objects
# │       │   ├── 00
# │       │   ├── ...
# │       │   └── ff
# │       ├── refs
# │       │   ├── heads
# │       │   ├── mirrors
# │       │   └── remotes
# │       ├── state
# │       ├── tmp
# │       │   └── cache
# │       └── config
# ├── proc
# ├── root
# ├── run
# ├── sys
# ├── tmp
# └── var
