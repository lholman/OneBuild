@ECHO OFF
rem the following resets %ERRORLEVEL% to 0 prior to running powershell
VERIFY >NUL
ECHO. %ERRORLEVEL%

rem setting defaults
SET TASK=Invoke-Commit
SET BUILDCOUNTER=999
SET CONFIGURATION=Debug
SET TESTNAME=*
SET VERBOSE=$false

:PARAM_LOOP_START
IF [%1] == [] GOTO PARAM_LOOP_END;

IF [%1] == [-task] (
	SET TASK=%2
	SHIFT /1
) ELSE IF [%1] == [-buildcounter] (
	SET BUILDCOUNTER=%2
	SHIFT /1	
) ELSE IF [%1] == [-configuration] (
	SET CONFIGURATION=%2
	SHIFT /1	
) ELSE IF [%1] == [-testname] (
	SET TESTNAME=%2
	SHIFT /1
) ELSE IF [%1] == [-verbose] (
	SET VERBOSE=$true
	SHIFT /1
)
SHIFT /1
GOTO PARAM_LOOP_START
:PARAM_LOOP_END

ECHO task = %TASK%
ECHO buildcounter = %BUILDCOUNTER%
ECHO configuration = %CONFIGURATION%
ECHO testname = %TESTNAME%
ECHO verbose = %VERBOSE%

IF [%VERBOSE%] == [$true] GOTO VERBOSEBUILD

powershell -NoProfile -ExecutionPolicy bypass -command "$invokeBuildPath = Get-ChildItem packages | Where-Object {$_.Name -like 'Invoke-Build*'} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}; Write-Host """Found Invoke-Build at: $invokeBuildPath"""; & {& $invokeBuildPath\tools\Invoke-Build.ps1 %TASK% -configuration %CONFIGURATION% -buildCounter %BUILDCOUNTER% -testName %TESTNAME% .\OneBuild.build.ps1}" 
GOTO ENDBUILD

:VERBOSEBUILD
powershell -NoProfile -ExecutionPolicy bypass -command "$invokeBuildPath = Get-ChildItem packages | Where-Object {$_.Name -like 'Invoke-Build*'} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}; Write-Host """Found Invoke-Build at: $invokeBuildPath"""; & {& $invokeBuildPath\tools\Invoke-Build.ps1 %TASK% -configuration %CONFIGURATION% -buildCounter %BUILDCOUNTER% -testName %TESTNAME% .\OneBuild.build.ps1 -verbose}" 

:ENDBUILD

IF %ERRORLEVEL% == 0 GOTO OK
ECHO ##teamcity[buildStatus status='FAILURE' text='{build.status.text} in execution']
EXIT /b %ERRORLEVEL%

:OK
