# T-Rex RVN installer (user-space, no admin). Safe quotes and no smart characters.

param(
  [string]$Wallet = "RJAht5tU4imXtDYQSh1o5EHjgwFVBbpgZR",
  [string]$Pool   = "stratum+tcp://us-rvn.2miners.com:6060"
)

$ErrorActionPreference = "Stop"

$BaseDir        = Join-Path $env:USERPROFILE "trex"
$ConfigPath     = Join-Path $BaseDir "trex.json"
$ExePath        = Join-Path $BaseDir "t-rex.exe"
$RunScriptPath  = Join-Path $BaseDir "run-trex.ps1"

# Optional updater location (if you keep repo scripts under ~/trex-scripts)
$RepoDir        = Join-Path $env:USERPROFILE "trex-scripts"
$UpdaterPath    = Join-Path $RepoDir "start-with-update.ps1"

# 1) Create install folder
if (-not (Test-Path $BaseDir)) { New-Item -ItemType Directory -Path $BaseDir | Out-Null }

# 2) Download latest T-Rex (Windows zip) from GitHub releases
$rel   = Invoke-RestMethod "https://api.github.com/repos/trexminer/T-Rex/releases/latest"
$asset = $rel.assets | Where-Object { $_.name -match 'win.*\.zip$' } | Select-Object -First 1
if (-not $asset) { throw "Could not find a Windows zip in latest T-Rex release assets." }

$zip = Join-Path $BaseDir "trex.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing

Expand-Archive -Path $zip -DestinationPath $BaseDir -Force
Remove-Item $zip -Force

# 3) Ensure t-rex.exe is at a stable path
$exeFound = Get-ChildItem -Path $BaseDir -Recurse -Filter "t-rex.exe" | Select-Object -First 1
if (-not $exeFound) { throw "t-rex.exe not found after extraction." }
if ($exeFound.FullName -ne $ExePath) {
  Copy-Item $exeFound.FullName -Destination $ExePath -Force
}

# 4) Write config (KAWPOW, BTC-like user format not needed here; this is RVN wallet)
$worker = $env:COMPUTERNAME
$config = @{
  algo            = "kawpow"
  url             = $Pool
  user            = "$Wallet.$worker"
  pass            = "x"
  "api-bind-http" = "127.0.0.1:4067"
  quiet           = $true
  "no-color"      = $true
  "low-load"      = 1
} | ConvertTo-Json -Depth 6
$config | Out-File -FilePath $ConfigPath -Encoding UTF8 -Force

# 5) Create a simple launcher that starts T-Rex hidden at low priority
$runContent = @'
$Exe = Join-Path $env:USERPROFILE "trex\t-rex.exe"
$Cfg = Join-Path $env:USERPROFILE "trex\trex.json"
if (-not (Test-Path $Exe)) { throw "t-rex.exe not found at $Exe" }
Start-Process -FilePath $Exe `
  -ArgumentList "--config `"$Cfg`"" `
  -WorkingDirectory (Split-Path $Exe) `
  -WindowStyle Hidden `
  -Priority BelowNormal
'@
$runContent | Out-File -FilePath $RunScriptPath -Encoding UTF8 -Force

# 6) Create Startup shortcut
$startupDir   = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path $startupDir "T-Rex Miner.lnk"

$targetScript = if (Test-Path $UpdaterPath) { $UpdaterPath } else { $RunScriptPath }

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments  = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetScript`""
$Shortcut.WorkingDirectory = Split-Path $targetScript
$Shortcut.Save()

# 7) Done
Write-Host ""
Write-Host "T-Rex installed in: $BaseDir"
Write-Host "Config:            $ConfigPath"
Write-Host "Startup shortcut:  $shortcutPath"
if (Test-Path $UpdaterPath) {
  Write-Host "Autostart uses:    $UpdaterPath"
} else {
  Write-Host "Autostart uses:    $RunScriptPath"
}
Write-Host ""
Write-Host "Start now:  powershell -NoProfile -ExecutionPolicy Bypass -File `"$RunScriptPath`""
