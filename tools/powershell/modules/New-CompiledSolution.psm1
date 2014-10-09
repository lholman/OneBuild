function New-CompiledSolution{
<#
 
.SYNOPSIS
    Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies for a target configuration (Debug|Release etc).
.DESCRIPTION
	Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies. Solution file to build is identified by convention, also allows optional passing of a target configuration (Debug|Release etc).
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER msBuildPath
	Optional. The full path to msbuild.exe.  Defaults to 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'.	
.PARAMETER configMode
	Optional. The build Configuration to be passed to msbuild during compilation. Examples include 'Debug' or 'Release'.  Defaults to 'Release' 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'.	
.PARAMETER nuGetPath
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.	
.PARAMETER basePath
	Optional. The path to the root parent folder to search for Visual Studio Solution (.sln) files in.  Defaults to the calling scripts path.		
.EXAMPLE 
	Import-Module New-CompiledSolution
	Import the module
.EXAMPLE	
	Get-Command -Module New-CompiledSolution
	List available functions
.EXAMPLE
	New-CompiledSolution 
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(Mandatory = $False )]
				[string]
				$msBuildPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe",	
			[Parameter(Mandatory = $False )]
				[string]
				$configMode = "Release",	
			[Parameter(Mandatory = $False )]	
				[string]
				$nuGetPath,
			[Parameter(Mandatory = $False)]
				[string]
				$basePath = ""					
			)			
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				Try 
				{
					#Set the basePath to the calling scripts path (using Resolve-Path .)
					#$basePath = Resolve-Path .
					$path = Confirm-Path -basePath $basePath
					if ($path -eq 1) { return 1}
				
					if ($nuGetPath -eq "")
					{
						#Set our default value for nuget.exe
						$callingScriptPath = Resolve-Path .
						$nuGetPath = "$callingScriptPath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
					}

					$solutionFile = Get-FirstSolutionFile
					
					if ($solutionFile -eq $null)
					{
						Write-Error "No solution (*.sln) file found to compile."
						Return 1
					}
					
					Write-Warning "Using Configuration mode '$($configMode)'. Modify this by passing in a value for the parameter '-configMode'"
										
					Restore-SolutionNuGetPackages -solutionFile $solutionFile -nuGetPath $nuGetPath
					
					$result = ""
					$result = Invoke-MsBuildCompilationForSolution -solutionFile $solutionFile -configMode $configMode
					
					if ($result) 
					{
						Write-Error "Whilst executing MsBuild for solution file $solutionFile, MsBuild.exe exited with error message: Root element is missing: $result"
						Return 1
					}
					
					Return 0
				}
				catch [Exception] {
					throw "Error compiling solution file: $solutionFile. `r`n $_.Exception.ToString()"
				}
		}
}
function Confirm-Path {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$basePath			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	$path = Get-Path -basePath $basePath
	Remove-Module Get-Path
	return $path
}

function Get-FirstSolutionFile {
	#Convention: Get the first solution file we find (ordered alphabetically) in the current folder. 
	return Get-ChildItem $basePath | Where-Object {$_.Extension -eq '.sln'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1
}

function Restore-SolutionNuGetPackages {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$solutionFile,	
		[Parameter(Mandatory = $True )]
			[string]$nuGetPath				
	)	
	Write-Host "Restoring NuGet packages for ""$solutionFile""."
	$output = & $nugetPath restore $solutionFile 2>&1 
	$err = $output | ? {$_.gettype().Name -eq "ErrorRecord"}
	
	if ($err)
	{
		Write-Host $output
		Return $err
	}
}

function Invoke-MsBuildCompilationForSolution {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$solutionFile,	
		[Parameter(Mandatory = $True )]
			[string]$configMode				
	)
	Write-Warning "Building '$($solutionFile)' in '$($configMode)' mode"
	$output = & $msbuildPath $solutionFile /t:ReBuild /t:Clean /p:Configuration=$configMode /p:PlatformTarget=AnyCPU /m 2>&1 
	$err = $output | ? {$_.GetType().Name -eq "ErrorRecord"}
	
	#As we've re-directed error output to standard output (stdout) using '2>&1', we have effectively suppressed stdout, therefore we write $output to Host here. 
	Write-Host "output $output"
	Write-Host "err $err"
	if ($err)
	{
		Return $err
	}

}

Export-ModuleMember -Function New-CompiledSolution