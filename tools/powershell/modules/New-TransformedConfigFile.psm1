function New-TransformedConfigFile{
<#
 
.SYNOPSIS
    Generates a new config transformation file given a source XML file path and XSLT transform file path.
.DESCRIPTION
    Generates a new config transformation file given a source XML file path and XSLT transform file path.
.PARAMETER sourceFile
	Required.  The full file path to the source XML file to be be transformed.
.PARAMETER transformFile
	Required.  The full file path to the XSLT transform file to be be used for transformation.	
.PARAMETER outputFile
	Optional.  The full file path to the resultant transformed XML output file.	
.PARAMETER cttPath
	Optional.  The full path to the ctt.exe command line executable. Defaults to '\packages\ConfigTransformationTool\tools\ctt.exe', i.e. OneBuilds ConfigTransformationTool NuGet dependency package. 
.EXAMPLE 
	Import-Module New-TransformedConfigFile
	Import the module
.EXAMPLE	
	Get-Command -Module New-TransformedConfigFile
	List available functions
.EXAMPLE
	New-TransformedConfigFile -basePath AssemblyInfo.cs
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
			if (-not $PSBoundParameters.ContainsKey('Verbose'))
			{
				$VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
			}
		}	
	Process {
				Try {
						Write-Verbose "New-TransformedConfigFile: Starting: New-TransformedConfigFile"
						$basePath = Confirm-Path -path ""

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
							$outputFile = "$basePath\$transformedFilesFolder\Output.xml"
						}

						Write-Verbose "New-TransformedConfigFile: Using source XML file: $sourceFile"
						Write-Verbose "New-TransformedConfigFile: Using XSLT transform file: $transformFile"
						Write-Verbose "New-TransformedConfigFile: Setting transformed output XML file to: $outputFile"
						
						if ($cttPath -eq "")
						{
							$callingScriptPath = Resolve-Path .
							$cttPath = Confirm-Path -path "$callingScriptPath\lib\ctt.exe"
							Write-Verbose "New-TransformedConfigFile: 'ctt.exe' command line path set to: $cttPath"
						}


						if (Test-Path $outputFile ) { 
							Write-Verbose "New-TransformedConfigFile: Deleting existing transform: $ouputFile"
							Remove-Item -force $outputFile -ErrorAction SilentlyContinue 
						}
						

						Invoke-ConfigTransformationTool -sourceFile $sourceFile -transformFile $transformFile -outputFile $outputFile -cttPath $cttPath
						
				} 
				catch [Exception] {
					throw "An error occurred transforming sourceFile: $sourceFile. `r`n $_"
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

	#Write-Verbose "New-TransformedConfigFile: & $cttPath source:""$sourceFile"" transform:""$transformFile"" destination:""$outputFile""" 
	$output = & $cttPath source:"$sourceFile" transform:"$transformFile" destination:"$outputFile" indent verbose 2>&1 
	$err = $output | ? {$_.gettype().Name -eq "ErrorRecord"}

	if ($err)
	{
		throw "Whilst executing ctt.exe for sourceFile: $sourceFile and transformFile: $transformFile, ctt.exe exited with error message: $err"
	}

	#As we've re-directed error output to standard output (stdout) using '2>&1', so that we can save it to a variable, we have effectively suppressed stdout, therefore we write $output to the Verbose stream here. 
	$VerbosePreference = "Continue"
	Write-Verbose ($output | Out-String)
	return

}

Export-ModuleMember -Function New-TransformedConfigFile
