@echo off
rem User-triggered local request; no installation, service or global hotkey registration.
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Dragon.ps1" -Restore
