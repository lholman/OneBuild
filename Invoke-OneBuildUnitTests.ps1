<#
.Synopsis 
	Runs the Pester (https://github.com/pester/Pester) based unit tests for OneBuild (http://lholman.github.io/OneBuild/index.html)

.Description
	OneBuild is a modular set of convention based .NET solution build scripts written in PowerShell, relying on Invoke-Build for task automation. See https://github.com/lholman/OneBuild form more details.
#>
function Invoke-OneBuildUnitTests {
	[CmdletBinding()]
	param(
		$testName = "*"
	)
	Begin {
			$DebugPreference = "Continue"
			if (-not $PSBoundParameters.ContainsKey('Verbose'))
			{
				$VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
			}			
			$BuildRoot = Resolve-Path .
			if ((Test-Path -path "$BuildRoot\tools\powershell\modules" ) -eq $True)
			{
				$baseModulePath = "$BuildRoot\tools\powershell\modules"
			}else{
				#We order descending so that we can easily drop in a locally built version of OneBuild with a later version number (i.e. with a high buildCounter value) for testing.
				$baseModulePath = Get-ChildItem .\packages -Recurse | Where-Object {$_.Name -like 'OneBuild.*' -and $_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
				$baseModulePath = "$baseModulePath\tools\powershell\modules"
			}

		}	
	Process {
	
		$pesterPath = Get-ChildItem "$BuildRoot\packages" | Where-Object {$_.Name -like 'pester*'} | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
		
		if ($pesterPath -eq $Null) 
		{
			throw "No pester NuGet package found under $BuildRoot\packages, maybe try restoring all NuGet packages?"
		}
		
		Import-Module "$pesterPath\tools\Pester.psm1"
		$result
		try {
			$result = Invoke-Pester -Path "$BuildRoot\tests\" -TestName $testName -PassThru -OutputXml $BuildRoot\TestResult.xml
			if ($result.FailedCount -ne 0) 
			{
				throw "$($result.FailedCount) OneBuild unit test(s) failed."
			}
		}
		catch {
			throw
		}
		finally {
			Remove-Module Pester
		}
	}

}