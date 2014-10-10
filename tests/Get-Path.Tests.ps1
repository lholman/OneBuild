$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Get-Path" {		
	Context "When module is invoked with NO path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = Join-Path "$here" "\.." -Resolve
		$result = ""
		try {
			$result = Get-Path
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should set the path to the calling scripts path" {
            $result | Should Be "$testBasePath"
        }		
	}
	
	Context "When module is invoked with a path (-path parameter) that DOES exist" {
		
		Import-Module "$baseModulePath\$sut"
		#Here we get the TestDrive using pesters $TestDrive variable which holds the full file system location to the temporary PSDrive. 
		$testBasePath = "$TestDrive"

		$result = ""
		try {
			$result = Get-Path -path $testBasePath
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should set the path to the calling scripts path" {
            $result | Should Be "$testBasePath"
        }		
	}

	Context "When module is invoked with a path (-path parameter) that does NOT exist" {

		Import-Module "$baseModulePath\$sut"	
		$testBasePath = "$TestDrive\NonExistentPath\"
		Mock -ModuleName $sut Write-Error {} -Verifiable -ParameterFilter {
            $Message -eq "Supplied path: $testBasePath does not exist."
        }
				
		$result = ""
		try {
			$result = Get-Path -path $testBasePath 
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should write a descriptive error" {
			Assert-VerifiableMocks
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


