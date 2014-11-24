function New-NuGetPackagesForConfig{
<#
 
.SYNOPSIS
    Given a path, will dynamically generate new versioned NuGet package(s) for application configuration matching a folder convention, based on any template NuGet spec (.nuspec) files found
.DESCRIPTION
 

.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER versionNumber
	Mandatory. The version number to stamp the resultant NuGet package with.
.PARAMETER nuGetPath
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.
.PARAMETER path
	Optional. The path to the parent folder to search for NuGet spec (.nuspec) template files in.  Defaults to the calling scripts path.	
.EXAMPLE 
	Import-Module New-NuGetPackagesForConfig
	Import the module
.EXAMPLE	
	Get-Command -Module New-NuGetPackagesForConfig
	List available functions
.EXAMPLE
	New-NuGetPackagesForConfig -specFilePath 
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
				
				if ($nuGetPath -eq "")
				{
					#Set our default value for nuget.exe
					$callingScriptPath = Resolve-Path .
					$nuGetPath = "$callingScriptPath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
				}
				$specFilePaths = Get-AllConfigTemplateNuSpecFiles -path $basePath
				
				if ($specFilePaths -eq $null)
				{
					Write-Warning "No NuGet '.nuspec' configuration template file(s) found matching the packaging naming convention, exiting without NuGet packaging."
					return 0
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
						
						#Find matching configuration folder structures for the specified project
						$result = Get-AllClientsForTemplateNuSpecFile
						
						#$result = Invoke-NuGetPack -nuGetPath $nuGetPath -specFilePath $specFilePath -versionNumber $versionNumber -path $basePath
													
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
				[string]$path			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	$basePath = Get-Path -path $path
	Remove-Module Get-Path
	return $basePath
}

function Get-AllConfigTemplateNuSpecFiles {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$path				
	)
	return Get-ChildItem $path | Where-Object {$_.Extension -eq '.nuspec'} | Where-Object {$_.Name -like "*configuration*"} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object
}

function Get-AllClientsForTemplateNuSpecFile {
	Param(			
			[Parameter(
				Mandatory = $True )]
				[string]$path			
		)	
	
	return Get-ChildItem "$path\configuration\application" | Where {$_.PSIContainer}
}

function Get-ApplicationPathFromTemplateNuSpecFile {

	#Open the template NuSpec file and return the 'src' value from the first file element
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

Export-ModuleMember -Function New-NuGetPackagesForConfig