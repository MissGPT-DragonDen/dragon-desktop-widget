@echo off
rem Explicit troubleshooting only: this console intentionally stays visible.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Dragon.ps1"
pause
