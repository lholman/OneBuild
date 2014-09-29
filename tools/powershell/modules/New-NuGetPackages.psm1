function New-NuGetPackages{
<#
 
.SYNOPSIS
    Given a path, will create a new versioned NuGet package for each NuGet spec (.nuspec) file found.
.DESCRIPTION
     Given a path, will create a new versioned NuGet package for each NuGet spec (.nuspec) file found, optionally allowing you to specify a version number and path to the NuGet console executable.

.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER versionNumber
	Mandatory. The version number to stamp the resultant NuGet package with.
.PARAMETER nuGetPath
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.
.PARAMETER includeSymbolsPackage
	Optional. If included, instructs the NuGet executable to include the -symbols switch, generating a matching symbols package containing the 'pdb's'. Defaults to $false.
.PARAMETER basePath
	Optional. The path to the root parent folder to search for NuGet spec (.nuspec) files in.  Defaults to the calling scripts path.	
.EXAMPLE 
	Import-Module New-NuGetPackages
	Import the module
.EXAMPLE	
	Get-Command -Module New-NuGetPackages
	List available functions
.EXAMPLE
	New-NuGetPackages -specFilePath 
	Execute the module
#>
	[cmdletbinding()]
		Param(		
			[Parameter(Mandatory = $True )]
				[string]
				$versionNumber,
			[Parameter(Mandatory = $False )]
				[string]
				$nuGetPath,
			[Parameter(Mandatory = $False )]
				[switch]
				$includeSymbolsPackage,
			[Parameter(Mandatory = $False)]
				[string]
				$basePath = ""			
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				$path = Confirm-Path -basePath $basePath
				if ($path -eq 1) { return 1}
				
				if ($nuGetPath -eq "")
				{
					#Set our default value for nuget.exe
					$callingScriptPath = Resolve-Path .
					$nuGetPath = "$callingScriptPath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
				}
				$specFilePaths = Get-AllNuSpecFiles -path $path
				
				if ($specFilePaths -eq $null)
				{
					Write-Warning "No NuGet '.nuspec' file found matching the packaging naming convention, exiting without NuGet packaging."
					return 0
				}
				
				if ((Test-Path -Path "$path\BuildOutput") -eq $False) 
				{
					$supressOutput = New-Item -ItemType directory -Path "$path\BuildOutput" -force
				}
					
				Try 
				{
					$result = ""
					
					ForEach ($specFilePath in $specFilePaths)
					{	
						if ($includeSymbolsPackage)
						{
							$result = Invoke-NuGetPackWithSymbols -nuGetPath $nuGetPath -specFilePath $specFilePath -versionNumber $versionNumber -path $path
						}
						else
						{
							$result = Invoke-NuGetPack -nuGetPath $nuGetPath -specFilePath $specFilePath -versionNumber $versionNumber -path $path
							
						}
						
						if ($result) 
						{
							Write-Error "Whilst executing NuGet Pack on spec file $specFilePath, NuGet.exe exited with error message: $result"
							Return 1
						}
					}
					
					Return 0
				}
				catch [Exception] {
					throw "Error executing NuGet Pack for supplied spec file: $specFilePath using NuGet from: $nuGetPath `r`n $_.Exception.ToString()"
					Return 1
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

function Get-AllNuSpecFiles {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$path				
	)
	#Convention: select all '.nuspec' files in the supplied folder
	return Get-ChildItem $path | Where-Object {$_.Extension -eq '.nuspec'} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object
}

function Invoke-NuGetPack {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$nuGetPath,
		[Parameter(Mandatory = $True )]
			[string]$specFilePath,		
		[Parameter(Mandatory = $True )]
			[string]$versionNumber,
		[Parameter(Mandatory = $True )]
			[string]$path				
	)
	
	$output = & $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory $path\BuildOutput 2>&1 
	$err = $output | ? {$_.gettype().Name -eq "ErrorRecord"}
	
	if ($err)
	{
		Write-Host $output
		Return $err
	}
}

function Invoke-NuGetPackWithSymbols {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$nuGetPath,
		[Parameter(Mandatory = $True )]
			[string]$specFilePath,		
		[Parameter(Mandatory = $True )]
			[string]$versionNumber,
		[Parameter(Mandatory = $True )]
			[string]$path				
	)
	$output = & $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory $path\BuildOutput -Symbols 2>&1 
	$err = $output | ? {$_.gettype().Name -eq "ErrorRecord"}
	
	if ($err)
	{
		Write-Host $output
		Return $err
	}
}

Export-ModuleMember -Function New-NuGetPackages