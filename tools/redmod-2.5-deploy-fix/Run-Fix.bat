@echo off
rem Double-click to run the fix. Add -Undo after the file name to undo it from a command prompt.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-REDmod-Deploy.ps1" %*
