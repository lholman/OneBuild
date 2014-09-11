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
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$basePath = "",
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[array]$deleteIncludePaths = @("bin","obj","BuildOutput")		
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				$path = Confirm-Path -basePath $basePath
				if ($path -eq $null)
				{
					Write-Error "Supplied basePath: $basePath does not exist."
					return 1
				}

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
			Position = 1,
			Mandatory = $False )]
			[string]$basePath = ""			
	)
	
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
	
	return $null
}

Export-ModuleMember -Function Remove-FoldersRecursively