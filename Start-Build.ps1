#*==========================================================================================
#* Requirements:
#* 1. Install PowerShell 2.0+ on local machine
#* 2. Execute from build.bat

#* Parameters: -task* (The build task type to run).
#*	(*) denotes required parameter, all others are optional.

#* Example use to run the default Invoke-DebugCompile task:  
#* .\Start-Build.ps1

#*==========================================================================================
#* Purpose: Wraps the core Start-BuildDefault.ps1 script and does the following
#* - starts by importing the psake PowerShell module (we have this in a relative path in source control) .
#* - it then invokes the default psake build script in the current working folder (i.e. Start-BuildDefault.ps1),
#* passing the first parameter passed to the batch file in as the psake task.  Start-BuildDefault.ps1 obviously does
#* all the build work for us.
#* - finally the psake PowerShell module is removed.

#*==========================================================================================
#*==========================================================================================
#* SCRIPT BODY
#*==========================================================================================
param([string]$task = "Invoke-Commit", [string]$msbuildPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe", [string]$configMode = "Debug", [string]$buildCounter = "999", [string]$updateNuGetPackages = $false, [string]$webDeployPackage = $false)

Write-Host "Using the following parameter values (sensible defaults used where parameter not supplied)"
Write-Host "task: $task"
Write-Host "msbuildPath: $msbuildPath"
Write-Host "configMode: $configMode"
Write-Host "buildCounter: $buildCounter"
Write-Host "updateNuGetPackages: $updateNuGetPackages"

#As the psake library location differs between dev and execution within a host project, we load psake by searching for it recursively 
#and loading the first one we find with a matching version number in the path
$psakeBasePath = Get-ChildItem . -Recurse | Where-Object {$_.Name -eq 'psake.psm1'} | Where-Object {$_.FullName -like '*4.3.2*'} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
Import-Module "$psakeBasePath"

$psake.use_exit_on_error = $true
Invoke-psake .\Start-BuildDefault.ps1 -t $task -framework '4.0' -parameters @{"p1"=$msbuildPath;"p2"=$configMode;"p3"=$buildCounter;"p4"=$updateNuGetPackages;"p5"=$webDeployPackage} 
Remove-Module [p]sake -ErrorAction 'SilentlyContinue'

if ($error -ne '') 
{ 
	Write-Host "$error"
    exit $error.Count
} 
