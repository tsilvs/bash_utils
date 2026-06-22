# TODO

Pre-made cron jobs / services to run screencap compression and subtitle generation in the background scheduled

With visual indication:

- GUI Status Window
- Status bar icons
- DE (GNOME / KDE) Notifications

## Code style

- [ ] Rewrite using this idiomatic reference:

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

- [ ] Add `compgen` for all scripts

## tree_utils

- [ ] `tree.meta()` — read per-directory `.meta` annotations and print inline with tree output.
  ```sh
  # Per-directory $dir/.meta file format (tab-separated):
  # .	This dir's description
  # subdir_name	Description of subdir
  # file_name	Description of file
  ```
  Walk tree, check each dir for `.meta`, merge annotations into `tree.` output (or emit as separate annotated listing). Prefer integrating via `tree`'s own flags if possible; fallback to post-processing `tree.paths` + joining `.meta` content.
