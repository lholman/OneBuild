function Get-NuGetPath {
<#
 
.SYNOPSIS
    
.DESCRIPTION
	
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.	
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
					#Set default value for nuget.exe
					$callingScriptPath = Resolve-Path .
					return "$callingScriptPath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
				}

				if (Test-Path $path) 
				{
					return $path
				}
				
				throw "Supplied path: $path does not exist"
		}
}


Export-ModuleMember -Function Get-NuGetPath