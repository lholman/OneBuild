$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Set-BuildNumberWithGitCommitDetail" {

	Context "When Git is not in the Windows path" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-EnvironmentPath { return "" }

		$result = ""
		try {
			Set-BuildNumberWithGitCommitDetail
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$result | Should Be "Unable to find Git defined within the Windows path variable. Please check Git is both installed and defined in the Windows path environment variable and try again." 
        }			
	}	
	
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


