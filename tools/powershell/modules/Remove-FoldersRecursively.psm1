function Remove-FoldersRecursively{
<#
 
.SYNOPSIS
    Recursively removes (deletes) all matching common .NET build folders from a supplied base folder path down.
.DESCRIPTION
    Recursively removes (deletes) all matching common .NET build folders from a supplied base folder path down, optionally allows passing of a custom list of folders to delete.
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER basePath
	Optional. The path to the root parent folder to execute the recursive remove from.  Defaults to the calling scripts path.
.PARAMETER deleteIncludePaths
	Optional. A string array separated list of folder names to remove recursively, any folders matching the names of the items in the list found below the basePath will be removed.  Defaults to @("bin","obj","BuildOutput")
.EXAMPLE 
	Import-Module Remove-FoldersRecursively
	Import the module
.EXAMPLE	
	Get-Command -Module Remove-FoldersRecursively
	List available functions
.EXAMPLE
	Remove-FoldersRecursively -deleteIncludePaths bin,obj,BuildOutput
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$basePath,
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[array]$deleteIncludePaths = @("bin","obj","BuildOutput")		
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				Try 
				{
					Write-Debug "Started"
					
					if ($basePath -eq "")
					{
						Write-Debug "Setting the basePath to the calling scripts path (using Resolve-Path .)"
						$basePath = Resolve-Path .
					}
					Get-ChildItem -Path $basePath -Include $deleteIncludePaths -Recurse | 
						#? { $_.psiscontainer -and $_.fullname -notmatch 'packages' } | #Uncomment to exclude a particular root folder
						foreach ($_) { 
							Write-Output "Cleaning: $_"
							Remove-Item $_ -Force -Recurse -ErrorAction SilentlyContinue		
						}	
				}
				catch [Exception] {
					throw "Error removing folders for supplied deleteIncludePaths: $deleteIncludePaths under path: $basePath `r`n $_.Exception.ToString()"
				}
		}
}