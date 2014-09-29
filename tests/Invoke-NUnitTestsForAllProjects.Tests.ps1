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
		
		$result = 0
		try {
			$result = Invoke-NUnitTestsForAllProjects -searchString $searchString
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

        It "Exits module with code 0" {
            $result | Should Be 0
        }		
	}
#}
#Describe "Invoke-NUnitTestsForAllProjects" {
	Context "When module is invoked with a basePath that does NOT exist" {

		Import-Module "$baseModulePath\$sut"	
		Mock -ModuleName $sut Confirm-Path { return 1 }
		$testBasePath = "$TestDrive\NonExistentPath\"
	
		$result = ""
		try {
			$result = Invoke-NUnitTestsForAllProjects -basePath $testBasePath
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}

        It "Should exit the module with code 1" {
            $result | Should Be 1
        }		
	}	
	
		
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


