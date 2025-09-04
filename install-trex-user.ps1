# Installs T-Rex in user space and creates a Startup shortcut that runs start-with-update.ps1
# Uses 2Miners RVN (US GPU) and your RVN wallet by default; --low-load enabled.

param(
  [string]$Wallet = "RJAht5tU4imXtDYQSh1o5EHjgwFVBbpgZR",
  [string]$Pool   = "stratum+tcp://us-rvn.2miners.com:6060"
)

$BaseDir   = "$env:USERPROFILE\trex"
$Config    = Join-Path $BaseDir "trex.json"
$ExePath   = Join-Path $BaseDir "t-rex.exe"

# Create install folder
New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

# Download latest T-Rex (Windows)
$rel   = Invoke-RestMethod "https://api.github.com/repos/trexminer/T-Rex/releases/latest"
$asset = $rel.assets | Where-Object { $_.name -match 'win.*\.zip$' } | Select-Object -First 1
if (-not $asset) { throw "Couldn't find a Windows zip in the latest T-Rex release." }
$zip = Join-Path $BaseDir "trex.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $BaseDir -Force
Remove-Item $zip -Force

# Flatten binary if extracted into a subfolder
$exe = Get-ChildItem -Path $BaseDir -Recurse -Filter "t-rex.exe" | Select-Object -First 1
if (-not $exe) { throw "t-rex.exe not found after extraction." }
if ($exe.FullName -ne $ExePath) { Copy-Item $exe.FullName -Destination $ExePath -Force }

# Build config (low-load instead of intensity)
$worker = $env:COMPUTERNAME
@{
  algo = "kawpow"
  url  = $Pool
  user = "$Wallet.$worker"
  pass = "x"
  "api-bind-http" = "127.0.0.1:4067"
  quiet = $true
  "no-color" = $true
  "low-load" = 1
} | ConvertTo-Json -Depth 5 | Out-File -FilePath $Config -Encoding utf8 -Force

# Create Startup shortcut that runs start-with-update.ps1 from your repo
$RepoDir   = "$env:USERPROFILE\trex-scripts"
$Updater   = Join-Path $RepoDir "start-with-update.ps1"
if (-not (Test-Path $Updater)) {
  Write-Warning "start-with-update.ps1 not found in $RepoDir. Create/commit it and re-run if you want auto-pull at logon."
}

$ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\T-Rex Miner (auto-update).lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments  = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Updater`""
$Shortcut.WorkingDirectory = $RepoDir
$Shortcut.Save()

Write-Host "`n✔ T-Rex installed in: $BaseDir"
Write-Host "✔ Config written to:  $Config"
Write-Host "✔ Autostart shortcut: $ShortcutPath"
Write-Host "`nIf you have not yet, commit start-with-update.ps1 to your repo so it can pull latest at logon."
