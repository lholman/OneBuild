function Get-Path{
<#
 
.SYNOPSIS
    Given a path will confirm it exists, returning it if it does and returning the calling scripts path if it does NOT. 
.DESCRIPTION
    Given a path will confirm it exists, returning it if it does and returning the calling scripts path if it does NOT. 
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER basePath
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
				$basePath = ""
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				if ($basePath -eq "")
				{
					#Set the basePath to the calling scripts path (using Resolve-Path .)
					return Resolve-Path .
				}
				if (Test-Path $basePath) 
				{
					#Write-Host "return basePath: $basePath"
					return $basePath
				}
				
				Write-Error "Supplied basePath: $basePath does not exist."
				return 1
		}
}

Export-ModuleMember -Function Get-Path