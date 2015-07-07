$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Invoke-NUnitTestsForAllProjects" {

	Context "When there are NO test assemblies" {
		
		Import-Module "$baseModulePath\$sut"
		$searchString = "test"

		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "No assemblies found matching the test naming convention ($searchString), exiting without executing tests."
        }
		
		try {
			Invoke-NUnitTestsForAllProjects -searchString $searchString
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}

		It "Writes a descriptive warning" {
			Assert-VerifiableMocks
		}

	}

}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


