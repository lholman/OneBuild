function Get-NuGetPath {
<#
 
.SYNOPSIS
    
.DESCRIPTION
	
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Optional. The path to the solution folder to search recursively for the nuget.exe console application under.  Defaults to the calling scripts path.	
.EXAMPLE 
	Import-Module Get-NuGetPath
	Import the module
.EXAMPLE	
	Get-Command -Module Get-NuGetPath
	List available functions
.EXAMPLE
	Get-NuGetPath 
	Execute the module
#>
	[cmdletbinding()]
		Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path = ""			
		)	
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				if ($path -eq "")
				{
					#Set the path to the calling scripts path (using Resolve-Path .)
					$path = Resolve-Path .
				}
				if (Test-Path $path) 
				{
					$newestNuGetPath = Get-ChildItem "$path\packages" -Recurse | Where-Object {$_.Name -like 'nuget.exe'} | Where-Object {$_.FullName -like '*nuget.commandline*'} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
					return $newestNuGetPath
				}
				
				throw "Supplied path: $path does not exist"

		}
}

function Get-NUnitPath {
<#
 
.SYNOPSIS
    
.DESCRIPTION
	
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Optional. The path to the solution folder to search recursively for the nunit.exe runner application under.  Defaults to the calling scripts path.	
.EXAMPLE 
	Import-Module Get-NUnitPath
	Import the module
.EXAMPLE	
	Get-Command -Module Get-NUnitPath
	List available functions
.EXAMPLE
	Get-NUnitPath 
	Execute the module
#>
	[cmdletbinding()]
		Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path = ""			
		)	
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				if ($path -eq "")
				{
					#Set the path to the calling scripts path (using Resolve-Path .)
					$path = Resolve-Path .
				}
				if (Test-Path $path) 
				{
					$newestNuGetPath = Get-ChildItem "$path\packages" -Recurse | Where-Object {$_.Name -like 'nunit-console.exe'} | Where-Object {$_.FullName -like '*nunit.runners*'} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
					return $newestNuGetPath
				}
				
				throw "Supplied path: $path does not exist"

		}
}

Export-ModuleMember -Function Get-NuGetPath, Get-NUnitPath