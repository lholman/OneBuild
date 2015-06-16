function New-CompiledSolution{
<#
 
.SYNOPSIS
    Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies for a target configuration (Debug|Release etc).
.DESCRIPTION
	Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies. MsBuild version and Solution file to build are identified by convention, also allows optional passing of a target configuration (Debug|Release etc).
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER windowsPath
	Optional. The full path to Windows on the host OS.  Defaults to 'C:\Windows'.	
.PARAMETER configMode
	Optional. The build Configuration to be passed to msbuild during compilation. Examples include 'Debug' or 'Release'.  Defaults to 'Release' 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'.	
.PARAMETER nuGetPath
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.	
.PARAMETER path
	Optional. The full path to the parent folder to look for Visual Studio Solution (.sln) files in.  Defaults to the calling scripts path.		
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
				$configMode = "Release",	
			[Parameter(Mandatory = $False )]	
				[string]
				$nuGetPath,
			[Parameter(Mandatory = $False)]
				[string]
				$path					
			)			
	Begin {
			$DebugPreference = "Continue"
			if (-not $PSBoundParameters.ContainsKey('Verbose'))
			{
				$VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
			}			
		}	
	Process {
				Try 
				{
					$basePath = Confirm-Path -path $path
				
					$script:msbuildPath = Get-LatestInstalled64BitMSBuildPathFromRegistry
 					
					$nuGetPath = Set-NuGetPath $nuGetPath

					$solutionFile = Get-FirstSolutionFile
					
					if ($solutionFile -eq $null)
					{
						throw "No solution file found to compile, use the -path parameter if the target solution file isn't in the solution root"
					}

					Write-Warning "Using Configuration mode '$($configMode)'. Modify this by passing in a value for the parameter '-configMode'"
										
					$nugetError = Restore-SolutionNuGetPackages -solutionFile $solutionFile -nuGetPath $nuGetPath
					
					if ($nugetError -ne $null) 
					{
						throw "Whilst executing NuGet to restore dependencies for solution file $solutionFile, NuGet.exe exited with error message: $nugetError"
					}
					
					$result = Invoke-MsBuildCompilationForSolution -solutionFile $solutionFile -configMode $configMode -msbuildPath $script:msbuildPath
					if ($result -ne $null) 
					{
						throw "Whilst executing MsBuild for solution file $solutionFile, MsBuild.exe exited with error message: $result"
					}
				}
				catch [Exception] {
					throw "Error executing New-CompiledSolution: $_"
				}
				
				return
		}
}

function Get-64BitMsBuildRegistryHive {

	$msBuildRegistryHive64Bit = "Registry::HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\"
	
	return Get-ChildItem $msBuildRegistryHive64Bit -ErrorAction SilentlyContinue | ? { ($_.PSChildName -match "^\d") } | ? {$_.property -contains "MSBuildToolsPath"} | sort {[int]($_.PSChildName)} -descending
}

function Get-LatestMsBuildToolsVersion {
	Param(			
		[Parameter(
			Mandatory = $True )]
			[Array]$msBuildToolsVersions			
		)	
	#Here we remove any version of msbuild that were shipped with .NET Framework version 2.0 and lower. .NET 2.0 is 	
	#if ($msBuildToolsVersions
	
	$latestMsBuildToolsVersion = $msBuildToolsVersions | Select-Object -First 1
	return (Get-ItemProperty $latestMsBuildToolsVersion.PSPath "MSBuildToolsPath")
}

function Get-LatestInstalled64BitMSBuildPathFromRegistry {
	
	$errorContext = "New-CompiledSolution:Get-LatestInstalled64BitMSBuildPathFromRegistry:"
	
	$allInstalled64BitMsBuildToolsVersions = Get-64BitMsBuildRegistryHive
	
	if ($allInstalled64BitMsBuildToolsVersions -eq $null)
	{
		throw "No 64-bit .NET Framework (C:\Windows\Microsoft.NET\Framework64) or 64-bit Visual Studio (C:\Program Files (x86)\MSBuild) installation of MSBuild found on the local system. OneBuild also assumes a 64-bit Windows OS install. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues"
	}

	Write-Verbose "$errorContext $($allInstalled64BitMsBuildToolsVersions.Count)"
	
	$latestInstalledMsBuildToolsVersion = Get-LatestMsBuildToolsVersion -msBuildToolsVersions $allInstalled64BitMsBuildToolsVersions
	$latestMsBuildToolsVersion = $latestInstalledMsBuildToolsVersion.PSChildName
	Write-Verbose "$errorContext $latestMsBuildToolsVersion"

	$msBuildToolsPath = $latestInstalledMsBuildToolsVersion.MSBuildToolsPath
	Write-Verbose "$errorContext $msBuildToolsPath"
	
	$msBuildPath = Join-Path -path $msBuildToolsPath -childpath "msbuild.exe"
	if (Test-Path $msBuildPath) {
		return $msBuildPath
	}

	throw "Highest identified MSBuildTools version ($latestMsBuildToolsVersion) contains NO 64-bit MSBuild assembly (\bin\amd64\MSBuild.exe). OneBuild assumes a 64-bit MSBuild installation, either .NET Framework or Visual Studio. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail."
}

function Get-LatestInstalledMSBuildPath {

	Write-Verbose "New-CompiledSolution\Get-LatestInstalledMSBuildPath: Searching for the latest installed version of MSBuild. Starting with Visual Studio MSBuild (ToolsVersion >= 12.0) and falling back to .NET Framework MSBuild (ToolsVersions 2.0,3.5,4.0)"
	Write-Verbose "New-CompiledSolution\Get-LatestInstalledMSBuildPath: \Windows path: $windowsPath"
	Write-Verbose "New-CompiledSolution\Get-LatestInstalledMSBuildPath: \Program Files (x86) path: $programFilesx86Path"
	
	if (Test-Path "$programFilesx86Path\MSBuild")
	{
			#From Visual Studio 2013 onwards, MSBuild is included with Visual Studio. See https://github.com/lholman/OneBuild/issues/12#issuecomment-67883504 for more details.
			$latestVisualStudioMSBuildVersionPath = $null 	
			
			$latestVisualStudioMSBuildVersionPath = Get-ChildItem "$programFilesx86Path\MSBuild" | Where-Object {$_.PSIsContainer -eq $true}
			
			$latestVisualStudioMSBuildVersionPath = $latestVisualStudioMSBuildVersionPath | Where-Object {$_.Name -match "^\d"} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1 
			
			if ($latestVisualStudioMSBuildVersionPath -ne $null)
			{
				Write-Verbose "New-CompiledSolution\Get-LatestInstalledMSBuildPath: Latest installed Visual Studio MSBuild version found: $latestVisualStudioMSBuildVersionPath"
			}
			
			if (Test-Path "$latestVisualStudioMSBuildVersionPath\bin\amd64\msbuild.exe") {
				return "$latestVisualStudioMSBuildVersionPath\bin\amd64\msbuild.exe"
			}
			else { 
				throw "Highest identified Visual Studio MSBuild version ($latestVisualStudioMSBuildVersionPath) contains NO 64-bit MSBuild assembly (\bin\amd64\MSBuild.exe). OneBuild assumes a 64-bit MSBuild installation, either .NET Framework or Visual Studio. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail."
			}
			
			
	} elseif (Test-Path "$windowsPath\Microsoft.NET\Framework64") {
	
		#Before Visual Studio 2013, MSBuild was included with the .NET Framework. See https://github.com/lholman/OneBuild/issues/12#issuecomment-67883504 for more details.
		$latestFrameworkMSBuildVersionPath = $null 
		
		$latestFrameworkMSBuildVersionPath = Get-ChildItem "$windowsPath\Microsoft.NET\Framework64" | Where-Object {$_.PSIsContainer -eq $true} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1 
		
		if ($latestFrameworkMSBuildVersionPath -ne $null)
		{
			Write-Verbose "New-CompiledSolution\Get-LatestInstalledMSBuildPath: Latest installed .NET Framework MSBuild version found: $latestFrameworkMSBuildVersionPath"
		}
		
		if (Test-Path "$latestFrameworkMSBuildVersionPath\msbuild.exe") {
		
			return "$latestFrameworkMSBuildVersionPath\msbuild.exe"
		}
		
	}
	
	throw "No 64-bit .NET Framework (C:\Windows\Microsoft.NET\Framework64) or 64-bit Visual Studio (C:\Program Files (x86)\MSBuild) installation of MSBuild found on the local system. OneBuild also assumes a 64-bit Windows OS install. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues"
}

function Confirm-Path {
	Param(			
		[Parameter(
			Mandatory = $False )]
			[string]$path			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	Try {
		$path = Get-Path -path $path
		return $path
	}
	Catch [Exception] {
		throw
	}
	Finally {
		Remove-Module Get-Path
	}
	
}

function Set-NuGetPath {
	Param(			
		[Parameter(
			Mandatory = $False )]
			[string]$path			
		)	
	Import-Module "$PSScriptRoot\CommonFunctions.psm1"
	Try {
		$path = Get-NuGetPath -path $path
		return $path
	}
	Catch [Exception] {
		throw
	}
	Finally {
		Remove-Module CommonFunctions
	}
	
}

function Get-FirstSolutionFile {
	#Convention: Get the first solution file we find (ordered alphabetically) in the current folder. 
	return Get-ChildItem $path | Where-Object {$_.Extension -eq '.sln'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1
}

function Restore-SolutionNuGetPackages {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$solutionFile,	
		[Parameter(Mandatory = $True )]
			[string]$nuGetPath				
	)	
	Write-Warning "Restoring NuGet packages for ""$solutionFile""."
	$output = & $nugetPath restore $solutionFile 2>&1 
	$err = $output | ? {$_.gettype().Name -eq "ErrorRecord"}

	if ($LASTEXITCODE -eq 1)
	{
		return $output
	}	
	
	#As we've re-directed error output to standard output (stdout) using '2>&1', we have effectively suppressed stdout, therefore we write $output to Host here. 
	Write-Host "NuGet output: $output"	
	return
}

function Invoke-MsBuildCompilationForSolution {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$solutionFile,	
		[Parameter(Mandatory = $True )]
			[string]$configMode,	
		[Parameter(Mandatory = $True )]
			[string]$msBuildPath					
	)
	$errorContext = "New-CompiledSolution:Invoke-MsBuildCompilationForSolution:"
	
	Write-Verbose "$errorContext Using MSBuild from: $msBuildPath" 
	Write-Verbose "$errorContext Building '$($solutionFile)' in '$($configMode)' mode"
	$output = & $msBuildPath $solutionFile /t:ReBuild /t:Clean /p:Configuration=$configMode /p:PlatformTarget=AnyCPU /m 2>&1 
	
	#$err = $output | ? {$_.GetType().Name -eq "ErrorRecord"}
	
	if ($LASTEXITCODE -eq 1)
	{
		return $output
	}
	
	#As we've re-directed error output to standard output (stdout) using '2>&1', we have effectively suppressed stdout, therefore we write $output to Host here. 
	Write-Host "MSBuild output: $output"
	return
}

Export-ModuleMember -Function New-CompiledSolution