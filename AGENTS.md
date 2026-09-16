# arch-install — agent guide

Personal vanilla Arch Linux installer. Five-phase pipeline orchestrated by
`bin/arch-install.sh`. Every phase sources `config/settings.sh` through
`bin/lib/common.sh` — never read or write values outside that file.

## Conventions

- **No curl cascade.** Phase 20 copies this repo to `/opt/arch-install` on the
  target; every later phase runs from that copy. Never fetch scripts from
  GitHub mid-install.
- **Dialog captures via temp files.** dialog writes results to stderr; use the
  `inputbox()`, `passwordbox()`, `menu()` helpers in `common.sh` — never
  `$(dialog ...)`.
- **State is merged, not overwritten.** `state_save KEY=VAL` adds or updates a
  key in `/var/lib/arch-install/state.env`. Multiple calls in one phase are
  safe.
- **CSV format.** `packages/apps.csv` — four columns:
  `category,source,package,description`. Source is `R` (pacman, official repos)
  or `A` (AUR, queued for yay). Never add a package without updating the
  corresponding phase's post-install hooks if one exists.
- **Phase scripts are named NN-something.sh** where the prefix defines execution
  order. Phases 10-30 run during live/chroot; 40-50 run as root/user after
  first boot.

## Validation

```sh
make check          # bash -n + shellcheck (if installed)
bash tests/manual-test.sh        # quick smoke tests, no root needed
make test           # requires podman: spins up archlinux pod, runs smoke tests
make test-full      # same, but also runs 40/50 for real (installs packages)
```

All scripts must pass `bash -n` before any commit. Smoke tests use
`tests/fake-dialog.sh` (honors `$DIALOG` from `common.sh`) so they run
headless. Interactive phases 10/20 (partitioning, pacstrap) are **not**
covered — they need real hardware or QEMU.

## Roadmap

Current state: rewritten into a 5-phase pipeline, unit-tested in a podman
archlinux pod, not yet run end-to-end on real hardware.

- [x] Restructure: phased `bin/` pipeline, config-driven settings
- [x] Podman test pod: `tests/{Containerfile,run-pod.sh,manual-test.sh}`
- [ ] Dry-run / auto mode (skip dialogs, use defaults from settings)
- [ ] Point 40/50 at the container's own pacman (validated; verify yay/AUR repackaging in pod)
- [ ] GRUB defaults: theme, timeout
- [ ] Post-install hooks per category (e.g. zsh shell, services)
- [ ] End-to-end test harness (QEMU or VM snapshot)
- [ ] Optional systemd-boot support (alternative to GRUB)
