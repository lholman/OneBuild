function Get-FilePath {
<#
 
.SYNOPSIS
    Returns the full path (including file name) to a given file name, $null is returned if there is no match. Throws an exception if the path doesn't exist.
.DESCRIPTION
    Returns the full path (including file name) to a given file name, $null is returned if there is no match. Throws an exception if the path doesn't exist. This function will search recursively down from the defined path and will also return the "latest" version of a file if multiple paths exist. This assumes a version number exists somewhere within the path.
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Optional. The path to the solution folder to search recursively for the nuget.exe console application under.  Defaults to the calling scripts path. Throws an exception if the path doesn't exist.	
.PARAMETER fileName
	Mandatory. The name of the file to search for, including file extension, e.g. 'nuget.exe'. $null is returned if there is no match.
.PARAMETER pathContains
	Optional. An optional string that must exist within the path of the executable (in addition to the fileName parameter). This can be useful if the file name exists within paths you'd like to ignore or if you want to be more efficient by searching limited paths. The -like parameter is used for matching and assumes whitespace matching (*) either side of the string. Defaults to an empty string.	
.EXAMPLE 
	Import-Module Get-FilePath
	Import the module
.EXAMPLE	
	Get-Command -Module Get-FilePath
	List available functions
.EXAMPLE
	Get-FilePath 
	Execute the module
#>
	[cmdletbinding()]
		Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path = "",	
			[Parameter(
				Mandatory = $True )]
				[string]$fileName = "",				
			[Parameter(
				Mandatory = $False )]
				[string]$pathContains = ""
			)	
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				if ($path -eq "")
				{
					$path = Resolve-Path .
				}
				$fullName = $null
				if (Test-Path $path) 
				{
					if ($pathContains -ne "")
					{
						Write-Verbose "CommonFunctions:Get-FilePath: Searching for paths containing '*$($pathContains)*'"
						$fullName = Get-ChildItem "$path" -Recurse | Where-Object {$_.FullName -like "*$($pathContains)*"} | Where-Object {$_.Name -like "$fileName"} | Sort-Object {$_.FullName} | Select-Object $_.FullName -Last 1 | Foreach-Object {$_.FullName}
					}else{
						$fullName = Get-ChildItem "$path" -Recurse | Where-Object {$_.Name -like "$fileName"} | Sort-Object {$_.FullName} | Select-Object $_.FullName -Last 1 | Foreach-Object {$_.FullName}
					}
					
					return $fullName
				}
				
				throw "CommonFunctions:Get-FilePath: Supplied path: '$($path)' does not exist"

		}
}

Export-ModuleMember -Function Get-FilePath