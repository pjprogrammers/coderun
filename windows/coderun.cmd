@echo off
rem coderun - Command Prompt launcher for the PowerShell runner.
rem
rem Keep this file in sync with install.ps1, which writes an equivalent
rem launcher into the user's install directory.
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0coderun.ps1" %*

exit /b %ERRORLEVEL%
