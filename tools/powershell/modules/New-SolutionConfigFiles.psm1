function New-SolutionConfigFiles{
<#
 
.SYNOPSIS
    Identifies all [config] paths under the given solution path.
.DESCRIPTION
    Identifies all [config] paths under the given solution path
.PARAMETER path
	Optional. The full path to the Visual Studio Solution parent folder to look for [config] folders in.  Defaults to the calling scripts path.	
.EXAMPLE 
	Import-Module New-SolutionConfigFiles
	Import the module
.EXAMPLE	
	Get-Command -Module New-SolutionConfigFiles
	List available functions
.EXAMPLE
	New-SolutionConfigFiles -basePath AssemblyInfo.cs
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(Mandatory = $False)]
				[string]
				$path					
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
						$basePath = Confirm-Path -path $path

				 		Get-ChildConfigFolders -path $basePath
					
				} catch [Exception] {
					throw "An error occurred generating config files under path: $basePath. `r`n $_"
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

function Get-ChildConfigFolders {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	#Convention: Get the full path to all [config] folders under the supplied path. 
	return Get-ChildItem $path -recurse | Where-Object {$_.Name -eq '[config]'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object 
}

Export-ModuleMember -Function New-SolutionConfigFiles
