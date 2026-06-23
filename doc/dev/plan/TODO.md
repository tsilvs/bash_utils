# TODO

## Tasks

### Scheduled media processing service

#### Context

+ Pre-made cron jobs / services for screencap compression and subtitle generation scheduled in background
+ Visual indication: GUI Status Window, status bar icons, DE (GNOME / KDE) notifications

#### Definition

+ [ ] Implement cron job / systemd service for screencap compression
+ [ ] Implement cron job / systemd service for subtitle generation
+ [ ] Add GUI Status Window
+ [ ] Add status bar icons
+ [ ] Add GNOME / KDE notification hooks

#### Acceptance / DoD

+ [ ] Services run and schedule without manual invocation
+ [ ] Visual indication works on GNOME and KDE

### Code style: idiomatic rewrite

#### Context

+ All scripts should use `process_opts` pattern via `case`/`shift`:

  ```sh
  process_opts() {
      while [[ "$#" -gt 0 ]] ; do
          case "$1" in
              "") ;; # Ignore empty arguments
              -h) ;&
              --help) usage ; exit 0 ;;
              --opt=*) opt="${1#--opt=}" ;;
              --alt=*) alt="${1#--alt=}" ;;
              *) bundle_opts+=("$1")
          esac
          shift 1
      done
  }
  ```

#### Definition

+ [ ] Rewrite all scripts using `process_opts` idiomatic reference above
+ [ ] Add `compgen`-based completion to all scripts

#### Acceptance / DoD

+ [ ] All scripts parse opts via `process_opts` pattern
+ [ ] All scripts expose `compgen` completion

### tree_utils: tree.meta()

#### Context

+ `tree.meta()` reads per-directory `.meta` annotation files and prints inline with tree output
+ `.meta` file format (tab-separated): `.` → this dir's description; `subdir_name` → subdir desc; `file_name` → file desc

#### Definition

+ [ ] Implement `tree.meta()` in `tree_utils.sh`
+ [ ] Walk tree; check each dir for `.meta`; merge annotations into `tree.` output or emit as annotated listing
+ [ ] Prefer `tree`'s own flags for integration; fallback to post-processing `tree.paths` + joining `.meta` content

#### Acceptance / DoD

+ [ ] `tree.meta()` reads `.meta` from each directory in tree
+ [ ] Annotations appear inline with tree output
