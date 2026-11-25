#requires -Version 5.1
<#
    G.A.M.M.A. Dialogue Voice-over installer
    ----------------------------------------
    Copies the four MO2 mods, the launcher tools and the command file into an
    existing GAMMA installation, enables exactly one dialogue language pack in
    the G.A.M.M.A profile, and creates a "GAMMA - Dialogue Voice" shortcut.

    Usage:
      Install.ps1
      Install.ps1 -GammaRoot "D:\Games\STALKER GAMMA\GAMMA" -Language uk
      Install.ps1 -NoDesktopShortcut
#>
[CmdletBinding()]
param(
    [string]$GammaRoot,

    [ValidateSet('ru', 'uk', 'en')]
    [string]$Language = 'ru',

    [switch]$NoDesktopShortcut
)

$ErrorActionPreference = 'Stop'
$ReleaseRoot = Split-Path -Parent $PSCommandPath
$Payload = Join-Path $ReleaseRoot 'payload'
$ProfileName = 'G.A.M.M.A'
$AddonName = 'G.A.M.M.A. Dialogue Voice Language'
$PackNames = @{
    ru = 'Russian Dialogue Voice-over'
    uk = 'Ukrainian Dialogue Voice-over'
    en = 'English Dialogue Voice-over'
}
$Order = @('ru', 'uk', 'en')
$ByteEncoding = [System.Text.Encoding]::GetEncoding(28591)

function Stop-Install {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $Payload)) {
    Stop-Install "payload folder not found next to Install.ps1."
}

# ---------------------------------------------------------------- locate GAMMA

if (-not $GammaRoot) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Select the GAMMA folder (the one containing ModOrganizer.exe)'
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
    $GammaRoot = $dialog.SelectedPath
}

$GammaRoot = (Resolve-Path -LiteralPath $GammaRoot).Path.TrimEnd('\')
$MoExe = Join-Path $GammaRoot 'ModOrganizer.exe'
$ProfileDir = Join-Path $GammaRoot "profiles\$ProfileName"
$ModList = Join-Path $ProfileDir 'modlist.txt'

if (-not (Test-Path -LiteralPath $MoExe)) {
    Stop-Install "ModOrganizer.exe not found in $GammaRoot"
}
if (-not (Test-Path -LiteralPath $ModList)) {
    Stop-Install "profile modlist not found: $ModList"
}

$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -eq 'ModOrganizer' -or
    $_.ProcessName -like 'AnomalyDX*' -or
    $_.ProcessName -eq 'AnomalyLauncher'
})
if ($running.Count -gt 0) {
    Stop-Install ("Close GAMMA and Mod Organizer 2 first. Running: " +
        (($running.ProcessName | Sort-Object -Unique) -join ', '))
}

$ToolsDir = Join-Path $GammaRoot 'tools\dialogue_voice'
$BackupDir = Join-Path $ToolsDir 'backups'
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# ---------------------------------------------------------------- backup profile

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $BackupDir "modlist.before-install-$stamp.txt"
Copy-Item -LiteralPath $ModList -Destination $backup -Force
Write-Host "Profile backed up to $backup"

# ---------------------------------------------------------------- copy payload

Write-Host "Copying mods and launcher to $GammaRoot ..."
Copy-Item -Path (Join-Path $Payload '*') -Destination $GammaRoot -Recurse -Force

foreach ($name in (@($AddonName) + @($Order | ForEach-Object { $PackNames[$_] }))) {
    $path = Join-Path $GammaRoot "mods\$name"
    if (-not (Test-Path -LiteralPath $path)) {
        Stop-Install "copy failed, missing mod folder: $path"
    }
}
foreach ($code in $Order) {
    $dialogDir = Join-Path $GammaRoot ("mods\{0}\gamedata\sounds\characters_voice\dialogs" -f $PackNames[$code])
    $clips = @(Get-ChildItem -LiteralPath $dialogDir -Filter *.ogg -File -ErrorAction SilentlyContinue).Count
    if ($clips -lt 5000) {
        Stop-Install ("{0} pack looks incomplete ({1} clips)." -f $PackNames[$code], $clips)
    }
}

foreach ($required in @(
    'Start GAMMA (Dialogue Voice).cmd',
    'tools\dialogue_voice\DialogueVoiceLauncher.ps1',
    'tools\dialogue_voice\DialogueVolume.ps1',
    'tools\dialogue_voice\DialogueOggVolume.cs'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $GammaRoot $required))) {
        Stop-Install "copy failed, missing file: $required"
    }
}

# ---------------------------------------------------------------- edit modlist

$raw = [System.IO.File]::ReadAllBytes($ModList)
$bom = @()
if ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF) {
    $bom = $raw[0..2]
    $raw = $raw[3..($raw.Length - 1)]
}
$text = $ByteEncoding.GetString($raw)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = $text -split '\r?\n'
$names = @($AddonName) + @($Order | ForEach-Object { $PackNames[$_] })

$keep = New-Object System.Collections.Generic.List[string]
$inserted = $false
foreach ($line in $lines) {
    if ($line -match '^[+-]' -and $names -contains $line.Substring(1)) { continue }
    $keep.Add($line)
    if (-not $inserted -and $line.TrimStart([char]0xFEFF) -match '^#') {
        foreach ($name in $names) {
            $prefix = if ($name -eq $AddonName -or $name -eq $PackNames[$Language]) { '+' } else { '-' }
            $keep.Add("$prefix$name")
        }
        $inserted = $true
    }
}
if (-not $inserted) {
    $index = 0
    foreach ($name in $names) {
        $prefix = if ($name -eq $AddonName -or $name -eq $PackNames[$Language]) { '+' } else { '-' }
        $keep.Insert($index++, "$prefix$name")
    }
}

$updated = ($keep -join $newline).TrimEnd([char[]]"`r`n") + $newline
$outBytes = $ByteEncoding.GetBytes($updated)
if ($bom.Count -gt 0) {
    $outBytes = [byte[]]($bom + $outBytes)
}
[System.IO.File]::WriteAllBytes($ModList, $outBytes)

# ---------------------------------------------------------------- verify

$check = $ByteEncoding.GetString([System.IO.File]::ReadAllBytes($ModList)) -split '\r?\n'
foreach ($name in $names) {
    $count = @($check | Where-Object { $_ -eq "+$name" -or $_ -eq "-$name" }).Count
    if ($count -ne 1) {
        Stop-Install "modlist entry for '$name' is not unique after install."
    }
}
$enabledPacks = @($Order | Where-Object { $check -contains "+$($PackNames[$_])" })
if ($enabledPacks.Count -ne 1 -or $enabledPacks[0] -ne $Language) {
    Stop-Install "could not enable exactly the '$Language' voice pack."
}
if ($check -notcontains "+$AddonName") {
    Stop-Install "could not enable $AddonName."
}

# ---------------------------------------------------------------- shortcut

if (-not $NoDesktopShortcut) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $lnkPath = Join-Path $desktop 'GAMMA - Dialogue Voice.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($lnkPath)
    $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $lnk.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f (Join-Path $ToolsDir 'DialogueVoiceLauncher.ps1')
    $lnk.WorkingDirectory = $GammaRoot
    $lnk.IconLocation = "$MoExe,0"
    $lnk.Description = 'GAMMA dialogue voice language launcher'
    $lnk.Save()
    Write-Host "Desktop shortcut created: $lnkPath"
}

Write-Host ''
Write-Host "Installed. Dialogue language: $Language"
Write-Host "Start GAMMA from the 'GAMMA - Dialogue Voice' shortcut."
Write-Host "Switch languages later in MCM -> Dialogue voice, then relaunch from the same shortcut."
