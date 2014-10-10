function Compress-FilesFromPath{
<#
 
.SYNOPSIS
    Compresses (archives/zips) all files within a supplied base folder path in to an archive of a specified name.  
.DESCRIPTION
    Recursively compresses (archives/zips) all files within a supplied base folder path in to an archive of the specified name.  
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Mandatory. The full path to the root parent folder to compress all files within.  
.PARAMETER archiveName
	Mandatory. A string representing the (extensionless) target archive file name.
.EXAMPLE 
	Import-Module Compress-FilesFromPath
	Import the module
.EXAMPLE	
	Get-Command -Module Compress-FilesFromPath
	List available functions
.EXAMPLE
	Compress-FilesFromPath -archiveName "myarchivedfile"
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(Mandatory = $True,
						HelpMessage="Please supply a value for path")]
				[ValidateNotNullOrEmpty()]
				[string]
				$path,
			[Parameter(Mandatory = $True,
						HelpMessage="Please supply an extensionless file name value for archiveName")]
				[ValidateNotNullOrEmpty()]
				[ValidateScript({$_ -notlike "*.*"})]
				[string]
				$archiveName
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				$basePath = Confirm-Path -path $path
				if ($basePath -eq 1) { return 1}
				
				Write-Host "Searching for files to compress within path: $basePath"
				if ((Get-ChildItem $basePath).Count -eq 0)
				{
					Write-Error "No files found with the path: $basePath, exiting without generating archive file."
					return 1
				}
				
				Try 
				{
					Compress-Files
					return 0
				}
				
				catch [Exception] {
					throw "Error compressing files within the supplied path: $basePath `r`n $_.Exception.ToString()"
					return 1
				}
		}
}

function Confirm-Path {
	Param(			
			[Parameter(
				Mandatory = $True )]
				[string]$path			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	$path = Get-Path -path $path
	Remove-Module Get-Path
	return $path
}

function Compress-Files {

}

Export-ModuleMember -Function Compress-FilesFromPath