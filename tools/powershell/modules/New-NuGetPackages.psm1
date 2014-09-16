function New-NuGetPackages{
<#
 
.SYNOPSIS
    Given a path, will create a new versioned NuGet package for each NuGet spec (.nuspec) file found.
.DESCRIPTION
     Given a path, will create a new versioned NuGet package for each NuGet spec (.nuspec) file found, optionally allowing you to specify a version number and path to the NuGet console executable.

.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER versionNumber
	Optional. The version number to stamp the resultant NuGet package with.
.PARAMETER nuGetPath
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.
.PARAMETER includeSymbolPackage
	Optional. If included, instructs the NuGet executable to include the -symbols switch, generating a matching symbols package containing the 'pdb's'. Defaults to $false.
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
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$versionNumber,
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[string]$nuGetPath,
			[Parameter(
				Position = 2,
				Mandatory = $False )]
				[switch]$includeSymbolPackage					
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				#Set the basePath to the calling scripts path (using Resolve-Path .)
				$basePath = Resolve-Path .
				if ($nuGetPath -eq "")
				{
					#Set our default value for nuget.exe
					$nuGetPath = "$basePath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
				}
				$specFilePaths = Get-AllNuSpecFiles
				
				if ($specFilePaths -eq $null)
				{
					Write-Warning "No NuGet '.nuspec' file found matching the packaging naming convention, exiting without NuGet packaging."
					return 0
				}
				
				if ((Test-Path -Path "$basePath\BuildOutput") -eq $True) { Remove-Item -Path "$basePath\BuildOutput" -Force	-Recurse}
				New-Item -ItemType directory -Path "$basePath\BuildOutput" -force
					
				Try 
				{
					ForEach ($specFilePath in $specFilePaths)
					{	
					
						if ($includeSymbolPackage)
						{
							return & $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory "BuildOutput" -Symbols
						}
						else
						{
							return & $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory "BuildOutput"	
						}

					}
					
				}
				catch [Exception] {
					throw "Error executing NuGet Pack for supplied spec file: $specFilePath using NuGet from: $nuGetPath `r`n $_.Exception.ToString()"
				}
		}
}

function Get-AllNuSpecFiles {
	#Convention: select all '.nuspec' files in the supplied folder
	return Get-ChildItem $basePath | Where-Object {$_.Extension -eq '.nuspec'} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object
}

Export-ModuleMember -Function New-NuGetPackages