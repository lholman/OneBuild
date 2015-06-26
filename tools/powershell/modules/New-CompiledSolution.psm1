function New-CompiledSolution{
<#
 
.SYNOPSIS
    Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies for a target configuration (Debug|Release etc).
.DESCRIPTION
	Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies. MsBuild version and Solution file to build are identified by convention, also allows optional passing of a target configuration (Debug|Release etc).
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
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
				
					$solutionFile = Get-FirstSolutionFile
					
					if ($solutionFile -eq $null)
					{
						throw "No solution file found to compile, use the -path parameter if the target solution file isn't in the solution root"
					}

					$script:msbuildPath = Get-LatestInstalled64BitMSBuildPathFromRegistry
 					
					$nuGetPath = Set-NuGetPath $nuGetPath
					$nugetError = Restore-SolutionNuGetPackages -solutionFile $solutionFile -nuGetPath $nuGetPath
					
					if ($nugetError -ne $null) 
					{
						throw "Whilst executing NuGet to restore dependencies for solution file $solutionFile, NuGet.exe exited with error message: $nugetError"
					}
					
					Write-Warning "Using Configuration mode '$($configMode)'. Modify this by passing in a value for the parameter '-configMode'"
					
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
			Mandatory = $False )]
			[Array]$msBuildToolsVersions			
		)	

	if ($msBuildToolsVersions -ne $null)
	{
		$errorContext = "New-CompiledSolution:Get-LatestMsBuildToolsVersion:"
		$toolsVersions = $msBuildToolsVersions | ForEach-Object {return $_.PSChildName}
		Write-Verbose "$errorContext Found a total of '$($toolsVersions.Count)' installed MSBuild ToolsVersion(s): '$($toolsVersions)'"		
		
		$supportedMSBuildVersions = $msBuildToolsVersions

		$nonSupportedMSBuildVersions = $msBuildToolsVersions | Sort-Object {[decimal]$_.PSChildName} | ForEach-Object {if ([decimal]$_.PSChildName -le 2.0 ) {return $_} }
		if ($nonSupportedMSBuildVersions.Count -gt 0)
		{
			$toolsVersions = $nonSupportedMSBuildVersions | ForEach-Object {return $_.PSChildName}
			Write-Verbose "$errorContext Found a total of '$($toolsVersions.Count)' NON-supported MSBuild ToolsVersion(s): '$($toolsVersions)'"	
			Write-Verbose "$errorContext OneBuild only supports MSBuild shipped with .NET Framework versions 3.5 and later (i.e. ToolsVersion >= 3.5). Refer to http://lholman.github.io/OneBuild/conventions.html for more detail."
			
			$supportedMSBuildVersions = $msBuildToolsVersions -ne $nonSupportedMSBuildVersions
		}

		$toolsVersions = $supportedMSBuildVersions | ForEach-Object {return $_.PSChildName}
		Write-Verbose "$errorContext Found a total of '$($toolsVersions.Count)' OneBuild supported MSBuild ToolsVersion(s): '$($toolsVersions)'"	
		
		$latestMsBuildToolsVersion = $supportedMSBuildVersions | Select-Object -First 1

		if ($latestMsBuildToolsVersion -ne $null)
		{
			return $latestMsBuildToolsVersion
		}

	}

	throw "No 64-bit .NET Framework (C:\Windows\Microsoft.NET\Framework64) or 64-bit Visual Studio (C:\Program Files (x86)\MSBuild) installation of MSBuild found on the local system. OneBuild also assumes a 64-bit Windows OS install. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues"
	
}

function Get-LatestInstalled64BitMSBuildPathFromRegistry {
	
	$errorContext = "New-CompiledSolution:Get-LatestInstalled64BitMSBuildPathFromRegistry:"
	
	$allInstalled64BitMsBuildToolsVersions = Get-64BitMsBuildRegistryHive
	
	$latestInstalledMsBuildToolsVersion = Get-LatestMsBuildToolsVersion -msBuildToolsVersions $allInstalled64BitMsBuildToolsVersions
		
	$latestInstalledMsBuildToolsPath = Get-ItemProperty -Path $latestInstalledMsBuildToolsVersion.PSPath -Name "MSBuildToolsPath"
	
	$latestMsBuildToolsVersion = $latestInstalledMsBuildToolsPath.PSChildName
	Write-Verbose "$errorContext $latestMsBuildToolsVersion"

	$msBuildToolsPath = $latestInstalledMsBuildToolsPath.MSBuildToolsPath
	Write-Verbose "$errorContext $msBuildToolsPath"
	
	Try {
		$msBuildPath = Confirm-Path -path (Join-Path -path $msBuildToolsPath -childpath "msbuild.exe")
	}
	Catch [Exception] {
		throw "Highest identified MSBuildTools version ($latestMsBuildToolsVersion) contains NO 64-bit MSBuild assembly (\bin\amd64\MSBuild.exe). OneBuild assumes a 64-bit MSBuild installation, either .NET Framework or Visual Studio. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail."
	}	
	return $msBuildPath
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
	Write-Verbose "Restoring NuGet packages for ""$solutionFile""."
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
	$output = (& $msbuildPath $solutionFile /t:ReBuild /t:Clean /p:Configuration=$configMode /p:RunOctoPack=true /p:PlatformTarget=AnyCPU /nr:false /m 2>&1) -join "`r`n"
	
	if ($LASTEXITCODE -eq 1)
	{
		return $output
	}
	
	#As we've re-directed error output to standard output (stdout) using '2>&1', we have effectively suppressed stdout, therefore we write $output to Host here. 
	Write-Host "MSBuild output: $output"
	return
}

Export-ModuleMember -Function New-CompiledSolution