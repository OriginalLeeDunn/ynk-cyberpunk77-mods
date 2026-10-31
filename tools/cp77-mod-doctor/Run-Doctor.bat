@echo off
rem Double-click to run Mod Doctor. Read-only: it never changes your game.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Doctor.ps1" %*
