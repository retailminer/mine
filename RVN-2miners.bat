@echo off
REM RavenCoin mining with T-Rex Miner
REM Wallet: RJAht5tU4imXtDYQSh1o5EHjgwFVBbpgZR
REM Pool:   stratum+tcp://us-rvn.2miners.com:6060

t-rex.exe -a kawpow -o stratum+tcp://us-rvn.2miners.com:6060 -u RJAht5tU4imXtDYQSh1o5EHjgwFVBbpgZR.%COMPUTERNAME% -p x --low-load

pause
