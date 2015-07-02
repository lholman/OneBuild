$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Confirm-WindowsBitness Check bitness" {

	$invokeBuildPath = Get-ChildItem packages | Where-Object {$_.Name -like 'Invoke-Build*'} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}; 
	#$sut = "$invokeBuildPath\tools\Invoke-Build.ps1"
	#. "$invokeBuildPath\tools\Invoke-Build.ps1"
	#Write-Host "sut: $sut"
	
	Context "When OS is 32 bit" {
	
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-WindowsOSBitness { return "32-Bit"}
		
		try {
			$result = Confirm-WindowsBitness -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits OneBuild with a descriptive terminating error" {
			
			$expectedErrorMessage = "Error running OneBuild: OneBuild assumes a 64-bit Windows OS install. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues" 	
			$result | Should Match $expectedErrorMessage
		}

	}
}


