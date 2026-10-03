@echo off
rem Ordinary launcher: no persistent console/taskbar window.
start "" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0Dragon.ps1"
exit /b
