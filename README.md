# Continuous Claude — releases

Binary distribution for **Continuous Claude** (the source repository is private; this repo hosts install scripts and release artifacts only).

Continuous Claude is an autonomous software-development pipeline for Claude Code: compiled hooks (statusline, tldr-read, diagnostics, auto-handoff), the Ouros research sandbox, readiness tooling, and an installer. Its process layer (skills/agents) is the public [Catalyst](https://github.com/TransmuteLabs/Catalyst) plugin, installed automatically.

## Install

**macOS / Linux:**

```sh
curl -fsSL https://raw.githubusercontent.com/TransmuteLabs/ContinuousClaude-releases/main/install.sh | sh
# with daemon auto-start and PATH setup:
curl -fsSL https://raw.githubusercontent.com/TransmuteLabs/ContinuousClaude-releases/main/install.sh | sh -s -- --autostart --add-path
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/TransmuteLabs/ContinuousClaude-releases/main/install.ps1 | iex
```

The installer (`cc-setup`) detects the platform, downloads the matching archive from this repo's Releases, verifies its SHA-256, places 5 binaries (`ContinuousClaude`, `cc-research`, `cc-hooks-client`, `cc-hooks-daemon`, `cc-setup`), generates `settings.json` hook wiring, and installs the Catalyst plugin.

Update / uninstall:

```sh
cc-setup update      # --check to only check
cc-setup uninstall
```

## What's in a release

| Asset | Purpose |
|---|---|
| `cc-<triple>.tar.gz` / `cc-<triple>.zip` | 5 binaries + minimal `.claude` (CLAUDE.md), with `.sha256` |
| `cc-setup-<triple>` | standalone installer binary, with `.sha256` |

Targets: `aarch64-apple-darwin`, `x86_64-apple-darwin`, `x86_64-unknown-linux-gnu`, `aarch64-unknown-linux-gnu`, `x86_64-pc-windows-msvc`.
