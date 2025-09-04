# T-Rex RVN Miner

## Install
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
$u="https://raw.githubusercontent.com/retailminer/mine/main/install-trex-user.ps1"; `
$i="$env:TEMP\install-trex-user.ps1"; `
iwr $u -OutFile $i -UseBasicParsing; `
powershell -NoProfile -ExecutionPolicy Bypass -File $i
`````````

## Remove
```powershell
Stop-Process -Name t-rex -Force -ErrorAction SilentlyContinue; `
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\T-Rex Miner.lnk" -Force -ErrorAction SilentlyContinue; `
Remove-Item "$env:USERPROFILE\trex" -Recurse -Force -ErrorAction SilentlyContinue
`````````
