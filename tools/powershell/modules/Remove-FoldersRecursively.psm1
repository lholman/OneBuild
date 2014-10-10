function Remove-FoldersRecursively{
<#
 
.SYNOPSIS
    Recursively removes (deletes) all folders from a supplied base folder path  that match a supplied array of include paths. 
.DESCRIPTION
    Recursively removes (deletes) all folders from a supplied base folder path  that match a supplied array of include paths. 
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER basePath
	Optional. The path to the root parent folder to execute the recursive remove from.  Defaults to the calling scripts path.
.PARAMETER deleteIncludePaths
	Optional. A string array separated list of folder names to remove recursively, any folders matching the names of the items in the list found below the basePath will be removed.
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
			[Parameter(Mandatory = $False)]
				[string]
				$basePath = "",
			[Parameter(Mandatory = $True,
						HelpMessage="Please supply a value for deleteIncludePaths")]
				[ValidateNotNullOrEmpty()]
				[array]
				$deleteIncludePaths		
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				$path = Confirm-Path -basePath $basePath
				if ($path -eq 1) { return 1}
				
				Write-Host "Searching for paths to delete, recursively from: $path"
				
				Try 
				{

					Get-ChildItem -Path $path -Include $deleteIncludePaths -Recurse | 
						#? { $_.psiscontainer -and $_.fullname -notmatch 'packages' } | #Uncomment to exclude a particular root folder
						foreach ($_) { 
							Write-Host "Cleaning: $_"
							Remove-Item $_ -Force -Recurse -ErrorAction SilentlyContinue		
						}	
					
					return 0
				}
				
				catch [Exception] {
					throw "Error removing folders for supplied deleteIncludePaths: $deleteIncludePaths under path: $path `r`n $_.Exception.ToString()"
					return 1
				}
		}
}

function Confirm-Path {
	Param(			
			[Parameter(
				Mandatory = $True )]
				[string]$basePath			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	$path = Get-Path -path $basePath
	Remove-Module Get-Path
	return $path
}

Export-ModuleMember -Function Remove-FoldersRecursively