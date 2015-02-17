function Transform-ConfigFile{
<#
 
.SYNOPSIS
    Generates a resultant config transformation given a number of source parameters
.DESCRIPTION
    Generates a resultant config transformation given a number of source parameters
.PARAMETER sourceFile
	Required.  The full file path to the source XML file to be be transformed.
.PARAMETER transformFile
	Required.  The full file path to the XSLT transform file to be be used for transformation.	
.PARAMETER outputFile
	Optional.  The full file path to the resultant transformed XML output file.	
.PARAMETER cttPath
	Optional.  The full path to the ctt.exe command line executable. Defaults to '\packages\ConfigTransformationTool\tools\ctt.exe', i.e. OneBuilds ConfigTransformationTool NuGet dependency package. 
.EXAMPLE 
	Import-Module Transform-ConfigFile
	Import the module
.EXAMPLE	
	Get-Command -Module Transform-ConfigFile
	List available functions
.EXAMPLE
	Transform-ConfigFile -basePath AssemblyInfo.cs
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(Mandatory = $True,
						HelpMessage="Please supply a full path")]
				[ValidateNotNullOrEmpty()]
				[string]
				$sourceFile,
			[Parameter(Mandatory = $True,
						HelpMessage="Please supply a full path")]
				[ValidateNotNullOrEmpty()]
				[string]
				$transformFile,	
			[Parameter(Mandatory = $False )]
				[string]$outputFile = "",					
			[Parameter(Mandatory = $False )]
				[string]$cttPath				
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				Write-Verbose "Starting: Transform-ConfigFile"
				Try {
					$basePath = Confirm-Path -path ""
				}
				Catch{
					throw $_
				}
				if (!(Test-Path -LiteralPath "$sourceFile"))
				{
					throw "Source file: $sourceFile does not exist."
					
				}
				if (!(Test-Path -LiteralPath "$transformFile"))
				{
					throw "Transform file: $transformFile does not exist."
				}					
				
				$transformedFilesFolder = "_TransformedConfigs"
				
				if ($outputFile -eq "")
				{
					#Set the path to the calling scripts path (using Resolve-Path .)
					$outputFile = "$basePath\$transformedFilesFolder\$($sourceFile.Name)"
				}

				Write-Verbose "Using source XML file: $sourceFile"
				Write-Verbose "Using XSLT transform file: $transformFile"
				Write-Verbose "Setting transformed output XML file to: $outputFile"
				
				if ($cttPath -eq "")
				{
					$cttPath = Confirm-Path -path "C:\Development\github\OneBuild\lib\ctt.exe"
					Write-Verbose "'ctt.exe' command line path set to: $cttPath"
				}


				if (Test-Path $outputFile ) { 
					Write-Verbose "Deleting existing transform: $ouputFile"
					Remove-Item -force $outputFile -ErrorAction SilentlyContinue 
				}
				
				Invoke-ConfigTransformationTool -sourceFile $sourceFile -transformFile $transformFile -outputFile $outputFile -cttPath $cttPath
				
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
	Catch {
		throw $_
	}
	Finally {
		Remove-Module Get-Path
	}
}

function Invoke-ConfigTransformationTool {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$sourceFile,	
		[Parameter(Mandatory = $True )]
			[string]$transformFile,	
		[Parameter(Mandatory = $True )]
			[string]$outputFile,
		[Parameter(Mandatory = $True )]
			[string]$cttPath		
	)
	
	<#								
	source:{file} (s:) - source file path
	transform:{file} (t:) - transform file path
	destination:{file} (d:) - destination file path

	E.g.: ctt.exe source:"source.config" transform:"transform.config" destination:"destination.config"
	#>	

	Try 
	{

		& $cttPath source:"$sourceFile" transform:"$transformFile" destination:"$outputFile"

	}
	catch [Exception] {
		throw "An unexpected error occurred whilst executing 'ctt.exe', with error message: `r`n $_"
	}

}

Export-ModuleMember -Function Transform-ConfigFile
