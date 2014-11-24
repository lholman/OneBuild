@echo off
  
rem the following resets %ERRORLEVEL% to 0 prior to running powershell
verify >nul
echo. %ERRORLEVEL%

if [%1]==[] (
	SET TASK=Invoke-Commit
) ELSE (
	SET TASK=%1
)

powershell -NoProfile -ExecutionPolicy bypass -command ".\packages\invoke-build.2.9.12\tools\Invoke-Build.ps1 %TASK% .\.build.ps1;exit $LASTEXITCODE"

if %ERRORLEVEL% == 0 goto OK
echo ##teamcity[buildStatus status='FAILURE' text='{build.status.text} in execution']
exit /b %ERRORLEVEL%

:OK
