## This is a chezmoi dotfiles repo

No `build`, `test`, `lint`, or `typecheck` commands. Changes here become dotfiles
on the target machine after `chezmoi apply`.

- Chezmoi CLI: `chezmoi` (v2.70.5+, installed via Homebrew)
- Source dir: `~/.local/share/chezmoi` (the workspace root)
- Preview changes: `chezmoi diff`
- Dry-run: `chezmoi apply --dry-run --verbose`
- Apply: `chezmoi apply`

## Template variables (set via `promptBoolOnce`)

| Variable             | Type | Default file / effect                                |
|----------------------|------|------------------------------------------------------|
| `personal_computer`  | bool | `.chezmoi.toml.tmpl` prompts on first apply          |
| `homelab_member`     | bool | Gates homelab packages in `.chezmoidata/packages.toml` |
| `dev_computer`       | bool | Gates dev packages + `.local/share/git_stopwords`    |
| `work_computer`      | bool | Gates `enabled_providers` in `opencode.json.tmpl`    |

Also `os` and `osRelease.id` are compound: e.g. `linux-ubuntu`, `darwin`.

## Key files / directories

- **`.chezmoi.toml.tmpl`** — chezmoi config template; also defines `[data]` block
  with email, github_user, hostname, XDG paths.
- **`.chezmoidata/packages.toml`** — declarative package lists stratified by
  `.common`, `.dev_computer`, `.homelab_member`, `.personal_computer`. Drives
  all package-install scripts.
- **`.chezmoiscripts/`** — lifecycle scripts:
  - `run_before_*` — pre-apply (prerequisites, 1Password setup)
  - `run_after_*` — post-apply (zsh, eza install)
  - `run_onchange_*` — triggered when data files change (apt, brew, snap,
    flatpak, asdf installs, and package removal)
  - bash scripts must be compatible with Bash 3.2.
- **`.chezmoitemplates/shared_script_utils.bash`** — shared bash library
  (logging, error handling, trap cleanup, `_uvBinaryPath_`, etc.) included by
  all scripts.
- **`.chezmoiexternal.toml`** — fetches `_eza` completions from GitHub weekly.
- **`.chezmoiignore`** — conditional ignores based on OS, available binaries,
  and `dev_computer`.
- **`.chezmoiremove`** — files chezmoi should delete from `$HOME` (legacy
  non-XDG paths).

## Formatting

- **Prettier** with `prettier-plugin-go-template` (repo config in
  `.prettierrc.toml`)
- **Taplo** for TOML files (config in `taplo.toml`):
  `taplo format` or check with `taplo check`

## Private entries

`dot_config/private_1Password/`, `dot_config/private_atuin/`,
`dot_config/private_mc/`, and `private_dot_ssh/config.tmpl` contain credentials.
Do not read or modify these unless explicitly asked.

## Git

- Remote: `git@github.com:Brenntron/dotfiles.git`
- `autoPush = false` in chezmoi config — chezmoi won't push; commits must be
  pushed manually.
- See `AGENTS-GLOBAL.md` for git workflow conventions and `dot_claude/CLAUDE.md`
  for general development principles.
