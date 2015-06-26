function Confirm-WindowsBitness{
<#
 
.SYNOPSIS
    Checks the current Windows Operating System bitness and throws an exception if it is not supported by OneBuild. 
.DESCRIPTION
    Checks the current Windows Operating System bitness and throws an exception if it is not supported by OneBuild. 
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER path
	Optional. The path confirm. Defaults to the calling scripts path.
.EXAMPLE 
	Import-Module Confirm-WindowsBitness
	Import the module
.EXAMPLE	
	Get-Command -Module Confirm-WindowsBitness
	List available functions
.EXAMPLE
	Confirm-WindowsBitness
	Execute the module
#>
	[cmdletbinding()]
	Param()
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				$windowsBitness = Get-WindowsOSBitness
				Write-Verbose "Windows OS bitness: $windowsBitness"
				
				if ($windowsBitness -ne "64-Bit")
				{
					throw "Error running OneBuild: OneBuild assumes a 64-bit Windows OS install. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues"
				}
		}
}

function Get-WindowsOSBitness {

	if ((Get-WmiObject -Class Win32_OperatingSystem -ComputerName localhost -ea 0).OSArchitecture -eq '64-bit') {            
		return "64-Bit"            
	} else  {            
		return "32-Bit"            
	} 
}

Export-ModuleMember -Function Confirm-WindowsBitness