function Get-Path{
<#
 
.SYNOPSIS
    Given a path will confirm it exists, returning it if it does and returning the calling scripts path if it does NOT. 
.DESCRIPTION
    Given a path will confirm it exists, returning it if it does and returning the calling scripts path if it does NOT. 
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Optional. The path confirm. Defaults to the calling scripts path.
.EXAMPLE 
	Import-Module Get-Path
	Import the module
.EXAMPLE	
	Get-Command -Module Get-Path
	List available functions
.EXAMPLE
	Get-Path
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(Mandatory = $False)]
				[string]
				$path = ""
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				if ($path -eq "")
				{
					#Set the path to the calling scripts path (using Resolve-Path .)
					return Resolve-Path .
				}
				if (Test-Path $path) 
				{
					#Write-Host "return path: $path"
					return $path
				}
				
				throw "Supplied path: $path does not exist"
		}
}

Export-ModuleMember -Function Get-Path