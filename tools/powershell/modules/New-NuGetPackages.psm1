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
			[Parameter(Mandatory = $True )]
				[string]$versionNumber,
			[Parameter(Mandatory = $False )]
				[string]$nuGetPath,
			[Parameter(Mandatory = $False )]
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
				
				#if ((Test-Path -Path "$basePath\BuildOutput") -eq $False) 
				#{ 
				#	New-Item -ItemType directory -Path "$basePath\BuildOutput" -force
				#}
					
				Try 
				{
					ForEach ($specFilePath in $specFilePaths)
					{	
						#Write-Host "specFilePath: $specFilePath"
						if ($includeSymbolPackage)
						{
							Invoke-NuGetPackWithSymbols -nuGetPath $nuGetPath -specFilePath $specFilePath -versionNumber $versionNumber
						}
						else
						{
							Invoke-NuGetPack -nuGetPath $nuGetPath -specFilePath $specFilePath -versionNumber $versionNumber
						}
					}
					
					Return 0
					
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

function Invoke-NuGetPack {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$nuGetPath,
		[Parameter(Mandatory = $True )]
			[string]$specFilePath,		
		[Parameter(Mandatory = $True )]
			[string]$versionNumber				
	)
	& $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory "BuildOutput" 
}

function Invoke-NuGetPackWithSymbols {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$nuGetPath,
		[Parameter(Mandatory = $True )]
			[string]$specFilePath,		
		[Parameter(Mandatory = $True )]
			[string]$versionNumber				
	)
	& $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory "BuildOutput"	-Symbols

}

Export-ModuleMember -Function New-NuGetPackages