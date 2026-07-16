# Continuous Claude — bootstrap installer (Windows, PowerShell).
#
# Downloads the self-contained cc-setup.exe for the current platform from GitHub
# Release and runs `cc-setup install`. All installation logic lives inside cc-setup.
#
# Usage:
#   irm https://raw.githubusercontent.com/<repo>/main/dist/install.ps1 | iex
#   # with arguments: set $env:CC_SETUP_ARGS before running, e.g.
#   #   $env:CC_SETUP_ARGS = "--autostart --add-path"; irm .../install.ps1 | iex
#
# Environment variables:
#   CC_SETUP_REPO    — owner/repo (defaults to the public releases repo
#                      TransmuteLabs/ContinuousClaude-releases; the source repo is private).
#   CC_SETUP_VERSION — a specific tag (vX.Y.Z); defaults to latest.
#   CC_SETUP_ARGS    — extra arguments for `cc-setup install`.
$ErrorActionPreference = 'Stop'

# Force TLS 1.2: Windows PowerShell 5.1 on .NET Framework < 4.7 starts with
# SecurityProtocol = Tls (1.0), and Invoke-WebRequest to GitHub fails on TLS
# negotiation. We add Tls12 to the current set (without clobbering Tls13 where present).
try {
  [Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {}

$repo    = if ($env:CC_SETUP_REPO) { $env:CC_SETUP_REPO } else { 'TransmuteLabs/ContinuousClaude-releases' }
$version = if ($env:CC_SETUP_VERSION) { $env:CC_SETUP_VERSION } else { 'latest' }

# ── Architecture detection → target triple ──────────────────────────
# PROCESSOR_ARCHITECTURE reflects the bitness of the CURRENT process: under 32-bit
# PowerShell (WOW64) on 64-bit Windows this is 'x86', even though the OS is 64-bit.
# Under WOW64, the real OS architecture lives in PROCESSOR_ARCHITEW6432 — we prefer
# it, otherwise installation would fail with an "unsupported" x86.
$arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
switch ($arch) {
  'AMD64' { $triple = 'x86_64-pc-windows-msvc' }
  # The release only builds x64. On ARM64 Windows there is NO aarch64 asset, so we
  # take the x64 binary — it runs via the built-in x64-on-ARM emulation. (When a
  # native aarch64-msvc asset appears — switch this back to 'aarch64-pc-windows-msvc'.)
  'ARM64' { $triple = 'x86_64-pc-windows-msvc' }
  default { Write-Error "cc-setup: unsupported architecture: $arch"; exit 1 }
}

# ── cc-setup binary URL ──────────────────────────────────────────────
if ($version -eq 'latest') {
  $base = "https://github.com/$repo/releases/latest/download"
} else {
  $base = "https://github.com/$repo/releases/download/$version"
}
$url = "$base/cc-setup-$triple.exe"

# ── Download to a temp file ───────────────────────────────────────────
$tmp = Join-Path $env:TEMP ("cc-setup-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$bin = Join-Path $tmp 'cc-setup.exe'

$ccArgs = @('install')
# Quote-aware tokenization. One token is a run of non-whitespace chunks and
# "…"-segments glued together: this way `--config-dir="C:\Program Files\CC"`
# stays as ONE token (rather than splitting on the internal space), while a bare
# `--flag` and `"a b"` are also covered. Quotes are stripped inside the token.
# Repeated spaces do not produce empty tokens (at least one character is required).
if ($env:CC_SETUP_ARGS) {
  foreach ($m in [regex]::Matches($env:CC_SETUP_ARGS, '(?:[^\s"]+|"[^"]*")+')) {
    $ccArgs += ($m.Value -replace '"', '')
  }
}

$code = 0
try {
  Write-Host "cc-setup: downloading $url"
  # ProgressPreference=SilentlyContinue: in Windows PowerShell 5.1, Invoke-WebRequest's
  # progress bar slows the download down 10-50x. -TimeoutSec: without it, a hung
  # (half-open) connection would hang forever.
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri $url -OutFile $bin -UseBasicParsing -TimeoutSec 300
  Write-Host "cc-setup: running install ($triple)"
  & $bin @ccArgs
  $code = $LASTEXITCODE
} finally {
  # Clean up the temp directory with the binary (otherwise it leaks).
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

# NOT `exit`: when run via `irm ... | iex`, it would close the user's entire
# PowerShell session. We report the error via Write-Error (ErrorActionPreference=Stop).
if ($code -ne 0) { Write-Error "cc-setup install exited with code $code" }
