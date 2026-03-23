# ─── Dotfiles Installer (Windows) ─────────────────────────────────────────────
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"
$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Success { param($msg) Write-Host "  [OK] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warn    { param($msg) Write-Host "  [!]  " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Err     { param($msg) Write-Host "  [X]  " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Info    { param($msg) Write-Host "  [>]  " -ForegroundColor Cyan -NoNewline; Write-Host $msg }
function Write-Dim     { param($msg) Write-Host "       $msg" -ForegroundColor DarkGray }

function Backup-And-Copy {
    param($Src, $Dest)
    if (Test-Path $Dest) {
        $content1 = Get-Content $Src -Raw -ErrorAction SilentlyContinue
        $content2 = Get-Content $Dest -Raw -ErrorAction SilentlyContinue
        if ($content1 -eq $content2) {
            Write-Dim "already up to date: $Dest"
            return
        }
        $backup = "$Dest.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Write-Warn "Backing up $Dest -> $backup"
        Move-Item $Dest $backup
    }
    $destDir = Split-Path -Parent $Dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $Src $Dest
    Write-Success "Copied $Dest"
}

# ─── Header ──────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ┌─────────────────────────────────┐" -ForegroundColor White
Write-Host "  │    Dotfiles Installer (Win)      │" -ForegroundColor White
Write-Host "  └─────────────────────────────────┘" -ForegroundColor White
Write-Host ""
Write-Dim "Source: $DotfilesDir"
Write-Host ""

# ─── Module selection ────────────────────────────────────────────────────────
Write-Host "  Select what to install:" -ForegroundColor White
Write-Host ""
Write-Host "  1) " -ForegroundColor Cyan -NoNewline; Write-Host "Terminal configs  " -NoNewline; Write-Host "(starship)" -ForegroundColor DarkGray
Write-Host "  2) " -ForegroundColor Cyan -NoNewline; Write-Host "Claude Code       " -NoNewline; Write-Host "(settings, skills, plugins)" -ForegroundColor DarkGray
Write-Host "  3) " -ForegroundColor Cyan -NoNewline; Write-Host "Everything"
Write-Host "  q) " -ForegroundColor Cyan -NoNewline; Write-Host "Quit"
Write-Host ""
$choice = Read-Host "  Choice [1/2/3/q]"
Write-Host ""

$installTerminal = $false
$installClaude = $false

switch ($choice) {
    "1" { $installTerminal = $true }
    "2" { $installClaude = $true }
    "3" { $installTerminal = $true; $installClaude = $true }
    "q" { Write-Host "  Bye!"; exit 0 }
    default { Write-Err "Invalid choice"; exit 1 }
}

# ─── Terminal (starship) ────────────────────────────────────────────────────
if ($installTerminal) {
    Write-Host "  -- Terminal --" -ForegroundColor White
    Write-Host ""

    # Install starship if missing
    if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
        $install = Read-Host "  starship not found. Install it? [Y/n]"
        if ($install -ne "n" -and $install -ne "N") {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-Info "Installing starship via winget..."
                winget install --id Starship.Starship -e --accept-package-agreements --accept-source-agreements
                if ($?) { Write-Success "Installed starship" } else { Write-Err "Failed to install starship" }
            } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
                Write-Info "Installing starship via scoop..."
                scoop install starship
                if ($?) { Write-Success "Installed starship" } else { Write-Err "Failed to install starship" }
            } else {
                Write-Warn "No package manager found. Install manually: https://starship.rs"
            }
        }
    } else {
        Write-Dim "starship already installed"
    }

    # Starship config
    $starshipDest = "$env:USERPROFILE\.config\starship.toml"
    Backup-And-Copy "$DotfilesDir\terminal\starship.toml" $starshipDest

    # Add starship init to PowerShell profile
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (-not (Test-Path $profilePath)) {
        $addInit = Read-Host "  Add starship init to PowerShell profile? [y/N]"
        if ($addInit -eq "y" -or $addInit -eq "Y") {
            $profileDir = Split-Path -Parent $profilePath
            if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
            Add-Content $profilePath "`n# Starship prompt`nInvoke-Expression (&starship init powershell)"
            Write-Success "Added starship init to $profilePath"
        }
    } elseif (-not (Select-String -Path $profilePath -Pattern "starship init" -Quiet -ErrorAction SilentlyContinue)) {
        $addInit = Read-Host "  Add starship init to PowerShell profile? [y/N]"
        if ($addInit -eq "y" -or $addInit -eq "Y") {
            Add-Content $profilePath "`n# Starship prompt`nInvoke-Expression (&starship init powershell)"
            Write-Success "Added starship init to $profilePath"
        }
    } else {
        Write-Dim "starship init already in PowerShell profile"
    }

    # Note about unsupported tools
    Write-Host ""
    Write-Warn "tmux and ble.sh are Linux-only — skipped on Windows"

    Write-Host ""
}

# ─── Claude Code ─────────────────────────────────────────────────────────────
if ($installClaude) {
    Write-Host "  -- Claude Code --" -ForegroundColor White
    Write-Host ""

    $claudeDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
    if (-not (Test-Path "$claudeDir\skills")) { New-Item -ItemType Directory -Path "$claudeDir\skills" -Force | Out-Null }

    # settings.json
    $settingsDest = "$claudeDir\settings.json"
    if (Test-Path $settingsDest) {
        Write-Host "  " -NoNewline; Write-Host "Existing settings.json found." -ForegroundColor Yellow
        Write-Host "    a) " -ForegroundColor Cyan -NoNewline; Write-Host "Overwrite " -NoNewline; Write-Host "(backup existing first)" -ForegroundColor DarkGray
        Write-Host "    b) " -ForegroundColor Cyan -NoNewline; Write-Host "Skip"
        $sc = Read-Host "    Choice [a/b]"
        if ($sc -eq "a" -or $sc -eq "A") {
            Backup-And-Copy "$DotfilesDir\claude\settings.json" $settingsDest
        } else {
            Write-Dim "Skipped settings.json"
        }
    } else {
        Backup-And-Copy "$DotfilesDir\claude\settings.json" $settingsDest
    }

    # Skills — copy each skill directory
    $skillsSrc = "$DotfilesDir\claude\skills"
    Get-ChildItem -Path $skillsSrc -Directory | ForEach-Object {
        $skillName = $_.Name
        $skillDest = "$claudeDir\skills\$skillName"
        if (Test-Path $skillDest) {
            Write-Dim "skill already exists: $skillName"
        } else {
            Copy-Item $_.FullName $skillDest -Recurse
            Write-Success "Copied skill: $skillName"
        }
    }

    # Marketplaces
    Write-Host ""
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Info "Adding plugin marketplaces..."
        foreach ($marketplace in @("anthropics/claude-code", "OthmanAdi/planning-with-files")) {
            try {
                claude plugin marketplace add $marketplace 2>$null
                Write-Success "Added $marketplace marketplace"
            } catch {
                Write-Dim "$marketplace - may already be added, or claude not authenticated"
            }
        }
    } else {
        Write-Warn "claude CLI not found. After installing Claude Code, run:"
        Write-Dim "claude plugin marketplace add anthropics/claude-code"
        Write-Dim "claude plugin marketplace add OthmanAdi/planning-with-files"
    }

    # List plugins
    Write-Host ""
    Write-Host "  Enabled plugins " -ForegroundColor White -NoNewline; Write-Host "(auto-installed by Claude Code):" -ForegroundColor DarkGray
    if (Test-Path $settingsDest) {
        try {
            $settings = Get-Content $settingsDest -Raw | ConvertFrom-Json
            $settings.enabledPlugins.PSObject.Properties | ForEach-Object {
                Write-Dim "  * $($_.Name)"
            }
        } catch {
            Write-Dim "(could not parse settings.json)"
        }
    }

    # Note about hooks
    Write-Host ""
    Write-Warn "notify.sh hook is Linux-only — skipped on Windows"

    Write-Host ""
}

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host "  Done!" -ForegroundColor Green
Write-Host ""
