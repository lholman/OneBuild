@echo off
rem the following resets %ERRORLEVEL% to 0 prior to running powershell
verify >nul
echo. %ERRORLEVEL%

rem setting defaults
SET TASK=Invoke-Commit
SET CONFIGURATION=Debug
SET BUILDCOUNTER=999


:PARAM_LOOP_START
IF [%1] == [] goto PARAM_LOOP_END;

IF [%1] == [-task] (
	SET TASK=%2
	SHIFT /1
) ELSE IF [%1] == [-buildcounter] (
	SET BUILDCOUNTER=%2
) ELSE IF [%1] == [-configuration] (
	SET CONFIGURATION=%2
	SHIFT /1
)
SHIFT /1
GOTO PARAM_LOOP_START
:PARAM_LOOP_END


ECHO task = %TASK%
ECHO configuration = %CONFIGURATION%
ECHO buildcounter = %BUILDCOUNTER%

powershell -NoProfile -ExecutionPolicy bypass -command ".\packages\invoke-build.2.9.12\tools\Invoke-Build.ps1 %TASK% -configuration %CONFIGURATION% -buildCounter %BUILDCOUNTER% .\OneBuild.build.ps1"

if %ERRORLEVEL% == 0 goto OK
echo ##teamcity[buildStatus status='FAILURE' text='{build.status.text} in execution']
exit /b %ERRORLEVEL%

:OK
