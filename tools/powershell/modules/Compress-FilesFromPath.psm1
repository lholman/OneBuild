function Compress-FilesFromPath{
<#
 
.SYNOPSIS
    Recursively compresses (archives/zips) all files and folders from a supplied folder path in to an archive of a specified name.  
.DESCRIPTION
    Recursively compresses (archives/zips) all files and folders from a supplied folder path in to an archive of a specified name, optionally allowing the 7Zip executable path to be specified. 
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Mandatory. The full path to the root parent folder to compress all files within.  
.PARAMETER archiveName
	Mandatory. A string representing the (extensionless) target archive file name.
.PARAMETER sevenZipPath
	Optional. The full path to the 7za.exe console application.  Defaults to 'packages\7zip.commandline.9.20.0.20130618\tools\7za.exe', i.e. the bundled version of 7Zip.	
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
				$archiveName,
			[Parameter(Mandatory = $False )]
				[string]
				$sevenZipPath				
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				$basePath = Confirm-Path -path $path
						
				$filesExist = Confirm-FilesInPath -path $basePath
				if (!$filesExist)
				{
					throw "No files found within the path: $basePath, exiting without generating archive file."
				}
				
				Try 
				{
					$exitCode = Compress-Files -path $path -archiveName $archiveName -sevenZipPath $sevenZipPath
					if ($exitCode -eq 1) 
					{
						Write-Error "Whilst generating 7Zip archive on path $path, 7za.exe exited with a non-terminating exit code: $exitCode. Meaning from 7-Zip: Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed"
					}
					elseif ($exitCode -gt 1)
					{
						throw "Whilst generating 7Zip archive on path $path, 7za.exe exited with a terminating exit code: $exitCode. Meaning from 7-Zip: Fatal error"
					}
				}
				
				catch [Exception] {
					throw
				}
				
				return
		}
}

function Confirm-Path {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	Try {
		$path = Get-Path -path $path
		return $path
	}
	Catch [Exception] {
		throw
	}
	Finally {
		Remove-Module Get-Path
	}
	
}

function Confirm-FilesInPath {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$path				
	)
	Write-Host "Searching for files to compress within path: $path"
	$files = Get-ChildItem $path | Where {! $_.PSIContainer } | foreach {$_.FullName} | Select-Object
	if ($files -ne $Null)
	{
		return $True
	}
	return $False
}

function Compress-Files {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$path,
		[Parameter(Mandatory = $True)]
			[string]
			$archiveName,			
		[Parameter(Mandatory = $False )]
			[string]
			$sevenZipPath			
	)
	Write-Host "Compressing all folder(s)/file(s) recursively from path: $path in to archive: $archiveName.zip"
	
	if ($sevenZipPath -eq "")
	{
		$callingScriptPath = Resolve-Path .
		$sevenZipPath = "$callingScriptPath\packages\7zip.commandline.9.20.0.20130618\tools\7za.exe"
	}
	$output = & $sevenZipPath a "$archiveName.zip" $path\ 2>&1 
	
	#As we've re-directed error output to standard output (stdout) using '2>&1', we have effectively suppressed stdout, therefore we write $output to Host here. 
	Write-Host $output
	
	return $LASTEXITCODE
}

Export-ModuleMember -Function Compress-FilesFromPath