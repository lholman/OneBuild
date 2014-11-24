function Remove-FoldersRecursively{
<#
 
.SYNOPSIS
    Recursively removes (deletes) all folders from a supplied base folder path  that match a supplied array of include paths. 
.DESCRIPTION
    Recursively removes (deletes) all folders from a supplied base folder path  that match a supplied array of include paths. 
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Optional. The path to the root parent folder to execute the recursive remove from.  Defaults to the calling scripts path.
.PARAMETER deleteIncludePaths
	Optional. A string array separated list of folder names to remove recursively, any folders matching the names of the items in the list found below the path will be removed.
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
				$path = "",
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
				$basePath = Confirm-Path -path $path
				if ($basePath -eq 1) { return 1}
				
				Write-Host "Searching for paths to delete, recursively from: $basePath"
				
				Try 
				{

					Get-ChildItem -Path $basePath -Include $deleteIncludePaths -Recurse | 
						#? { $_.psiscontainer -and $_.fullname -notmatch 'packages' } | #Uncomment to exclude a particular root folder
						foreach ($_) { 
							Write-Host "Cleaning: $_"
							Remove-Item $_ -Force -Recurse -ErrorAction SilentlyContinue		
						}	
					
					return 0
				}
				
				catch [Exception] {
					throw "Error removing folders for supplied deleteIncludePaths: $deleteIncludePaths under path: $basePath `r`n $_.Exception.ToString()"
					return 1
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

Export-ModuleMember -Function Remove-FoldersRecursively