#requires -Version 5.1
<#
	Start GAMMA (Dialogue Voice)
	---------------------------
	Applies the selected dialogue voice language to the portable Mod Organizer 2
	profile "G.A.M.M.A" and starts the existing "Anomaly (DX11-AVX)" executable
	through Mod Organizer 2.

	The only profile entries this script touches are:
		+/- Russian Dialogue Voice-over
		+/- Ukrainian Dialogue Voice-over
		+/- English Dialogue Voice-over
	Every other line of modlist.txt is preserved byte for byte. The profile is
	written atomically and a timestamped backup is kept in .\backups.

	Usage:
  DialogueVoiceLauncher.ps1                 Apply the saved MCM choice and launch
  DialogueVoiceLauncher.ps1 -PickLanguage   Choose a language and launch
  DialogueVoiceLauncher.ps1 -Language uk    Save Ukrainian and launch
  DialogueVoiceLauncher.ps1 -Language en    Save English and launch
  DialogueVoiceLauncher.ps1 -NoLaunch       Apply the saved choice without starting MO2
  DialogueVoiceLauncher.ps1 -Status         Read the saved choice and profile flags
#>
[CmdletBinding()]
param(
	[ValidateSet('ru', 'uk', 'en')]
	[string]$Language,

	[switch]$PickLanguage,
	[switch]$NoLaunch,

	[switch]$Status
)

$ErrorActionPreference = 'Stop'

$ToolDir    = Split-Path -Parent $PSCommandPath
$GammaRoot  = Split-Path -Parent (Split-Path -Parent $ToolDir)
$GameRoot   = Join-Path (Split-Path -Parent $GammaRoot) 'Anomaly'
$MoExe      = Join-Path $GammaRoot 'ModOrganizer.exe'
$Profile    = 'G.A.M.M.A'
$ProfileDir = Join-Path $GammaRoot "profiles\$Profile"
$ModList    = Join-Path $ProfileDir 'modlist.txt'
$BackupDir  = Join-Path $ToolDir 'backups'
$LogPath    = Join-Path $ToolDir 'launcher.log'
$ConfigRelative = 'gamedata\configs\axr_options.ltx'
$McmKey = 'gamma_dialogue_voice/language'
$ByteEncoding = [System.Text.Encoding]::GetEncoding(28591)
$RuName = 'Russian Dialogue Voice-over'
$UkName = 'Ukrainian Dialogue Voice-over'
$EnName = 'English Dialogue Voice-over'
$RuDir  = Join-Path $GammaRoot "mods\$RuName\gamedata\sounds\characters_voice\dialogs"
$UkDir  = Join-Path $GammaRoot "mods\$UkName\gamedata\sounds\characters_voice\dialogs"
$EnDir  = Join-Path $GammaRoot "mods\$EnName\gamedata\sounds\characters_voice\dialogs"
$AddonName = 'G.A.M.M.A. Dialogue Voice Language'
$AddonDir  = Join-Path (Join-Path $GammaRoot 'mods') $AddonName

$BlockedProcesses = @(
	'ModOrganizer',
	'AnomalyDX8', 'AnomalyDX8AVX',
	'AnomalyDX9', 'AnomalyDX9AVX',
	'AnomalyDX10', 'AnomalyDX10AVX',
	'AnomalyDX11', 'AnomalyDX11AVX',
	'AnomalyLauncher', 'VerifiedDX11'
)

# ---------------------------------------------------------------- helpers

function Write-Log {
	param([string]$Message)
	try {
		$line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
		Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
	}
	catch {
		# logging must never stop the launch
	}
	Write-Host $Message
}

function Backup-File {
	param([string]$Path)
	if (-not (Test-Path -LiteralPath $Path)) { return $null }
	if (-not (Test-Path -LiteralPath $BackupDir)) {
		New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
	}
	$name = [System.IO.Path]::GetFileName($Path)
	$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'
	$dest = Join-Path $BackupDir ("{0}.{1}.bak" -f $name, $stamp)
	Copy-Item -LiteralPath $Path -Destination $dest -Force
	return $dest
}

function Prune-Backups {
	param([string]$Name, [int]$Keep = 30)
	$files = @(Get-ChildItem -LiteralPath $BackupDir -Filter "$Name.*.bak" -File -ErrorAction SilentlyContinue |
		Sort-Object LastWriteTime -Descending)
	if ($files.Count -gt $Keep) {
		$files[$Keep..($files.Count - 1)] | Remove-Item -Force -ErrorAction SilentlyContinue
	}
}

function Write-AtomicBytes {
	param([string]$Path, [byte[]]$Bytes)

	$tmp = '{0}.tmp-{1}' -f $Path, $PID
	$replaceBackup = '{0}.replbak-{1}' -f $Path, $PID
	try {
		[System.IO.File]::WriteAllBytes($tmp, $Bytes)
		[System.IO.File]::Replace($tmp, $Path, $replaceBackup)
	}
	finally {
		if ([System.IO.File]::Exists($tmp)) {
			[System.IO.File]::Delete($tmp)
		}
		if ([System.IO.File]::Exists($replaceBackup)) {
			[System.IO.File]::Delete($replaceBackup)
		}
	}
}

function Get-RunningBlocked {
	@(Get-Process -ErrorAction SilentlyContinue |
		Where-Object { $BlockedProcesses -contains $_.ProcessName })
}

function Find-McmConfig {
	param([string[]]$ProfileLines)

	# MO2 gives Overwrite priority, then reads enabled mods from the top of modlist.txt.
	$overwrite = Join-Path (Join-Path $GammaRoot 'overwrite') $ConfigRelative
	if ([System.IO.File]::Exists($overwrite)) { return $overwrite }

	foreach ($line in $ProfileLines) {
		if (-not $line.StartsWith('+')) { continue }
		$modRoot = Join-Path (Join-Path $GammaRoot 'mods') $line.Substring(1)
		$file = Join-Path $modRoot $ConfigRelative
		if ([System.IO.File]::Exists($file)) { return $file }
	}
	return (Join-Path $GameRoot $ConfigRelative)
}

function Read-McmSelection {
	param([string]$Path)

	# Latin-1 round-trips the original bytes, including comments in legacy encodings.
	$content = $ByteEncoding.GetString([System.IO.File]::ReadAllBytes($Path))
	$section = [regex]::Match($content, '(?mi)^\[mcm\][^\r\n]*(?:\r?\n|$)(?<body>[\s\S]*?)(?=^\[|\z)')
	$key = [regex]::new(('(?mi)^[ \t]*{0}[ \t]*=[ \t]*(?<value>[^;\r\n]*)' -f [regex]::Escape($McmKey)))
	$entry = $key.Match($section.Groups['body'].Value)
	$value = $entry.Groups['value'].Value.Trim()
	[pscustomobject]@{
		Content = $content
		Section = $section
		Entry = $entry
		Value = if ($value -cin @('ru', 'uk', 'en')) { $value }
	}
}

function Set-McmLanguage {
	param([string]$Path, [string]$Value)

	$options = Read-McmSelection -Path $Path
	if ($options.Value -ceq $Value) { return }

	$content = $options.Content
	$newline = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }
	$body = $options.Section.Groups['body']
	if ($options.Entry.Success) {
		$oldValue = $options.Entry.Groups['value']
		$index = $body.Index + $oldValue.Index
		$trailing = $oldValue.Value.Substring($oldValue.Value.TrimEnd().Length)
		$content = $content.Remove($index, $oldValue.Length).Insert($index, $Value + $trailing)
	}
	elseif ($options.Section.Success) {
		$prefix = if ($body.Index -gt 0 -and $content[$body.Index - 1] -ne "`n") { $newline } else { '' }
		$content = $content.Insert($body.Index, "$prefix$McmKey = $Value$newline")
	}
	else {
		$content += "$newline[mcm]$newline$McmKey = $Value$newline"
	}
	$null = Backup-File $Path
	Write-AtomicBytes -Path $Path -Bytes $ByteEncoding.GetBytes($content)
	Prune-Backups ([System.IO.Path]::GetFileName($Path))
}

function Get-VoiceCounts {
	$ru = @(Get-ChildItem -LiteralPath $RuDir -Filter *.ogg -File -ErrorAction SilentlyContinue).Count
	$uk = @(Get-ChildItem -LiteralPath $UkDir -Filter *.ogg -File -ErrorAction SilentlyContinue).Count
	$en = @(Get-ChildItem -LiteralPath $EnDir -Filter *.ogg -File -ErrorAction SilentlyContinue).Count
	return [pscustomobject]@{ Ru = $ru; Uk = $uk; En = $en }
}

function Get-ProfileVoiceState {
	param([string[]]$Lines)
	$ru = @($Lines | Where-Object { $_ -eq "+$RuName" -or $_ -eq "-$RuName" })
	$uk = @($Lines | Where-Object { $_ -eq "+$UkName" -or $_ -eq "-$UkName" })
	$en = @($Lines | Where-Object { $_ -eq "+$EnName" -or $_ -eq "-$EnName" })
	[pscustomobject]@{
		RuCount   = $ru.Count
		UkCount   = $uk.Count
		EnCount   = $en.Count
		RuEnabled = ($ru.Count -eq 1 -and $ru[0] -eq "+$RuName")
		UkEnabled = ($uk.Count -eq 1 -and $uk[0] -eq "+$UkName")
		EnEnabled = ($en.Count -eq 1 -and $en[0] -eq "+$EnName")
	}
}

function Show-Picker {
	param([string]$Default)

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing

	$form = New-Object System.Windows.Forms.Form
	$form.Text = 'GAMMA dialogue voice language'
	$form.Size = New-Object System.Drawing.Size(520, 330)
	$form.StartPosition = 'CenterScreen'
	$form.FormBorderStyle = 'FixedDialog'
	$form.MaximizeBox = $false
	$form.MinimizeBox = $false
	$form.TopMost = $true

	$title = New-Object System.Windows.Forms.Label
	$title.Text = 'Dialogue voice language'
	$title.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
	$title.Location = New-Object System.Drawing.Point(20, 15)
	$title.Size = New-Object System.Drawing.Size(460, 28)
	$form.Controls.Add($title)

	$info = New-Object System.Windows.Forms.Label
	$info.Text = 'Choose the language you want to hear when you talk to characters.'
	$info.Location = New-Object System.Drawing.Point(22, 48)
	$info.Size = New-Object System.Drawing.Size(460, 34)
	$form.Controls.Add($info)

	$radioRu = New-Object System.Windows.Forms.RadioButton
	$radioRu.Text = 'Russian (Русский)'
	$radioRu.Location = New-Object System.Drawing.Point(24, 92)
	$radioRu.Size = New-Object System.Drawing.Size(300, 24)
	$form.Controls.Add($radioRu)

	$radioUk = New-Object System.Windows.Forms.RadioButton
	$radioUk.Text = 'Ukrainian (Українська)'
	$radioUk.Location = New-Object System.Drawing.Point(24, 122)
	$radioUk.Size = New-Object System.Drawing.Size(300, 24)
	$form.Controls.Add($radioUk)

	$radioEn = New-Object System.Windows.Forms.RadioButton
	$radioEn.Text = 'English (English)'
	$radioEn.Location = New-Object System.Drawing.Point(24, 152)
	$radioEn.Size = New-Object System.Drawing.Size(300, 24)
	$form.Controls.Add($radioEn)

	if ($Default -eq 'en') { $radioEn.Checked = $true }
	elseif ($Default -eq 'uk') { $radioUk.Checked = $true }
	else { $radioRu.Checked = $true }

	$note = New-Object System.Windows.Forms.Label
	$note.Text = 'Mod Organizer 2 and the game must be closed. The choice is saved and applied to the G.A.M.M.A profile before launch.'
	$note.Location = New-Object System.Drawing.Point(22, 186)
	$note.Size = New-Object System.Drawing.Size(470, 40)
	$form.Controls.Add($note)

	$ok = New-Object System.Windows.Forms.Button
	$ok.Text = 'Apply and launch'
	$ok.Location = New-Object System.Drawing.Point(270, 243)
	$ok.Size = New-Object System.Drawing.Size(130, 30)
	$ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$form.AcceptButton = $ok
	$form.Controls.Add($ok)

	$cancel = New-Object System.Windows.Forms.Button
	$cancel.Text = 'Cancel'
	$cancel.Location = New-Object System.Drawing.Point(408, 243)
	$cancel.Size = New-Object System.Drawing.Size(90, 30)
	$cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	$form.CancelButton = $cancel
	$form.Controls.Add($cancel)

	$result = $form.ShowDialog()
	if ($result -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
	if ($radioEn.Checked) { return 'en' }
	if ($radioUk.Checked) { return 'uk' }
	return 'ru'
}

# ---------------------------------------------------------------- preflight

if (-not (Test-Path -LiteralPath $ModList)) {
	Write-Host "ERROR: profile modlist not found: $ModList" -ForegroundColor Red
	exit 3
}
if (-not (Test-Path -LiteralPath $MoExe)) {
	Write-Host "ERROR: ModOrganizer.exe not found: $MoExe" -ForegroundColor Red
	exit 3
}

$counts = Get-VoiceCounts
if ($counts.Ru -lt 5000 -or $counts.Uk -lt 5000 -or $counts.En -lt 5000) {
	Write-Host ("ERROR: dialogue voice packs look incomplete (Russian {0} clips, Ukrainian {1} clips, English {2} clips)." -f $counts.Ru, $counts.Uk, $counts.En) -ForegroundColor Red
	exit 3
}

$profileText = $ByteEncoding.GetString([System.IO.File]::ReadAllBytes($ModList))
$profileLines = $profileText -split '\r?\n'
$state = Get-ProfileVoiceState -Lines $profileLines
if ($state.RuCount -ne 1 -or $state.UkCount -ne 1 -or $state.EnCount -ne 1) {
	throw "Expected exactly one Russian, one Ukrainian and one English voice pack entry in $ModList."
}

$addonLine = @($profileLines | Where-Object { $_ -eq "+$AddonName" })
$addonReady = ($addonLine.Count -eq 1) -and (Test-Path -LiteralPath (Join-Path $AddonDir 'gamedata\scripts\gamma_dialogue_voice_mcm.script')) -and (Test-Path -LiteralPath (Join-Path $AddonDir 'gamedata\configs\text\eng\gamma_dialogue_voice_mcm.xml')) -and (Test-Path -LiteralPath (Join-Path $AddonDir 'gamedata\configs\text\rus\gamma_dialogue_voice_mcm.xml'))
. (Join-Path $ToolDir 'DialogueVolume.ps1')

$mcmConfig = Find-McmConfig -ProfileLines ([System.IO.File]::ReadAllLines($ModList))
$mcmLanguage = (Read-McmSelection -Path $mcmConfig).Value
$dialogueVolume = Get-DialogueVolume $mcmConfig
$enabledPacks = @()
if ($state.RuEnabled) { $enabledPacks += 'ru' }
if ($state.UkEnabled) { $enabledPacks += 'uk' }
if ($state.EnEnabled) { $enabledPacks += 'en' }
$mountedLanguage = if ($enabledPacks.Count -eq 1) { $enabledPacks[0] }
$savedLanguage = if ($mcmLanguage) { $mcmLanguage }
	elseif ($mountedLanguage) { $mountedLanguage }
	else { 'ru' }

if ($Status) {
	Write-Host "Profile           : $Profile"
	Write-Host "Dialogue volume   : $dialogueVolume%"
	Write-Host "MCM file          : $mcmConfig"
	Write-Host "MCM selection     : $(if ($mcmLanguage) { $mcmLanguage } else { '(not set)' })"
	Write-Host "MCM addon         : $(if ($addonReady) { 'enabled' } else { 'MISSING' })"
	Write-Host "Russian enabled   : $($state.RuEnabled)"
	Write-Host "Ukrainian enabled : $($state.UkEnabled)"
	Write-Host "English enabled   : $($state.EnEnabled)"
	Write-Host "Russian clips     : $($counts.Ru)"
	Write-Host "Ukrainian clips   : $($counts.Uk)"
	Write-Host "English clips     : $($counts.En)"
	exit 0
}

if (-not $Language) {
	$Language = $savedLanguage
	if ($PickLanguage) {
		$Language = Show-Picker -Default $savedLanguage
		if (-not $Language) { exit 0 }
	}
}
$Language = $Language.ToLowerInvariant()

$running = Get-RunningBlocked
if ($running.Count -gt 0) {
	$names = ($running | Select-Object -ExpandProperty ProcessName -Unique) -join ', '
	Write-Host "Close GAMMA and Mod Organizer 2 before switching dialogue audio. Running: $names" -ForegroundColor Red
	exit 2
}

# Save an explicit picker choice first. A retry can then apply that same choice.
if (-not $addonReady) {
	throw "The MCM addon '$AddonName' is not enabled or is incomplete in profile '$Profile'. Restore it before launching."
}
Set-McmLanguage -Path $mcmConfig -Value $Language
$savedMcm = (Read-McmSelection -Path $mcmConfig).Value
if ($savedMcm -cne $Language) {
	throw "The MCM setting '$McmKey' did not save as '$Language' in $mcmConfig."
}
Write-Log "Saved MCM setting '$McmKey' = '$Language' in $mcmConfig."
if ($mountedLanguage -ne $Language) {
	$packEntries = @(
		[pscustomobject]@{ Name = $RuName; Code = 'ru' },
		[pscustomobject]@{ Name = $UkName; Code = 'uk' },
		[pscustomobject]@{ Name = $EnName; Code = 'en' }
	)
	$updated = $profileText
	foreach ($pack in $packEntries) {
		$prefix = if ($Language -eq $pack.Code) { '+' } else { '-' }
		$updated = $updated -creplace ('(?m)^[+-]{0}(?=\r?$)' -f [regex]::Escape($pack.Name)), "$prefix$($pack.Name)"
	}

	$verify = Get-ProfileVoiceState -Lines ($updated -split '\r?\n')
	if ($verify.RuEnabled -ne ($Language -eq 'ru') -or
		$verify.UkEnabled -ne ($Language -eq 'uk') -or
		$verify.EnEnabled -ne ($Language -eq 'en')) {
		throw "Could not set the dialogue voice packs in $ModList."
	}
	$activeProfile = $ByteEncoding.GetString([System.IO.File]::ReadAllBytes($ModList))
	if ($activeProfile -cne $profileText) {
		throw 'Mod Organizer changed the profile while the launcher was running. Start GAMMA again.'
	}
	$backup = Backup-File $ModList
	Write-AtomicBytes -Path $ModList -Bytes $ByteEncoding.GetBytes($updated)
	Prune-Backups ([System.IO.Path]::GetFileName($ModList))
	Write-Log "Applied dialogue voice '$Language' to profile '$Profile' (backup: $backup)."
}
else {
	Write-Log "Dialogue voice '$Language' is already enabled in profile '$Profile'."
}

$voiceDirectories = @{ ru = $RuDir; uk = $UkDir; en = $EnDir }
Set-DialogueVolume -Directory $voiceDirectories[$Language] -Percent $dialogueVolume

if (-not $NoLaunch) {
	$moArguments = '--profile "{0}" "moshortcut://:Anomaly (DX11-AVX)"' -f $Profile
	Write-Log "Starting GAMMA through Mod Organizer 2 ($Profile)."
	Start-Process -FilePath $MoExe -ArgumentList $moArguments -WorkingDirectory $GammaRoot -WindowStyle Hidden
}
