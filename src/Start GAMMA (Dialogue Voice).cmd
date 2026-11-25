@echo off
setlocal
set "script=%~dp0tools\dialogue_voice\DialogueVoiceLauncher.ps1"
if "%~1"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" -PickLanguage
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" %*
)
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" pause
exit /b %RC%
