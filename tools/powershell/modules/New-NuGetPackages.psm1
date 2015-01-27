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
.PARAMETER includeSymbolsPackage
	Optional. If included, instructs the NuGet executable to include the -symbols switch, generating a matching symbols package containing the 'pdb's'. Defaults to $false.
.PARAMETER path
	Optional. The path to the parent folder to search for NuGet spec (.nuspec) files in.  Defaults to the calling scripts path.	
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
				[switch]
				$includeSymbolsPackage,
			[Parameter(Mandatory = $False)]
				[string]
				$path = ""			
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				$basePath = Confirm-Path -path $path
				if ($basePath -eq 1) { return 1}
				
				Import-Module "$PSScriptRoot\CommonFunctions.psm1"
				$nuGetPath = Get-NuGetPath

				$specFilePaths = Get-AllNuSpecFiles -path $basePath
				
				if ($specFilePaths -eq $null)
				{
					Write-Warning "No NuGet '.nuspec' file found matching the packaging naming convention, exiting without NuGet packaging."
				}
				
				if ((Test-Path -Path "$basePath\BuildOutput") -eq $False) 
				{
					$supressOutput = New-Item -ItemType directory -Path "$basePath\BuildOutput" -force
				}
					
				Try 
				{
					$result = ""
					
					ForEach ($specFilePath in $specFilePaths)
					{	
						if ($includeSymbolsPackage)
						{
							$result = Invoke-NuGetPackWithSymbols -nuGetPath $nuGetPath -specFilePath $specFilePath -versionNumber $versionNumber -path $basePath
						}
						else
						{
							$result = Invoke-NuGetPack -nuGetPath $nuGetPath -specFilePath $specFilePath -versionNumber $versionNumber -path $basePath
							
						}
						
						if ($result) 
						{
							throw "An error occurred whilst executing Nuget Pack for the .nuspec file: $specFilePath. Nuget.exe exited with error message: $result"
							
						}
					}
					
				}
				catch [Exception] {
					throw "An unexpected error occurred whilst executing Nuget Pack for the .nuspec file: $specFilePath. Nuget.exe path: $nuGetPath nuget.exe. Nuget.exe exited with error message: `r`n $_"
				}
		}
}

function Confirm-Path {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	$basePath = Get-Path -path $path
	Remove-Module Get-Path
	return $basePath
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

	#As we've re-directed error output to standard output (stdout) using '2>&1', we have effectively suppressed stdout, therefore we write $output to Host here. 	
	Write-Host $output
	
	if ($err)
	{
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

	#As we've re-directed error output to standard output (stdout) using '2>&1', we have effectively suppressed stdout, therefore we write $output to Host here. 
	Write-Host $output
	
	if ($err)
	{
		Return $err
	}
}

Export-ModuleMember -Function New-NuGetPackages