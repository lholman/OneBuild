$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")

Describe "OneBuild.build Check bitness" {

	$invokeBuildPath = Get-ChildItem packages | Where-Object {$_.Name -like 'Invoke-Build*'} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}; 
	#$sut = "$invokeBuildPath\tools\Invoke-Build.ps1"
	#. "$invokeBuildPath\tools\Invoke-Build.ps1"
	#Write-Host "sut: $sut"
	
	Context "When OS is 32 bit" {
	
		#. "$here\..\OneBuild.build.ps1"
		Mock Get-WindowsBitness { return "32-Bit"}
		
		#Invoke the OneBuild Invoke-Build build script
		
		$result = & $invokeBuildPath\tools\Invoke-Build.ps1 Invoke-Commit "$here\..\OneBuild.build.ps1" -verbose
		
		It "Exits OneBuild with a descriptive terminating error" {
			
			$expectedErrorMessage = "Error running OneBuild: OneBuild assumes a 64-bit Windows OS install. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues" 	
			$result | Should Match $expectedErrorMessage
		}

	}
}


