$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


Describe "Remove-FoldersRecursively_1" {		
	Context "When module is invoked with an empty deleteIncludePaths parameter" {
		
		Import-Module "$baseModulePath\$sut"
		#Calling script is the root of the OneBuild folder, where Invoke-Build invokes pester

		$testBasePath = Join-Path "$here" "\.." -Resolve

		$result = ""
		try {
			Remove-FoldersRecursively -deleteIncludePaths @()
		}
		#catch [System.Management.Automation.ParameterBindingValidationException] {
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should throw a terminating exception" {
			$result | Should Match "Cannot validate argument on parameter 'deleteIncludePaths'"
		}		
	}
}

Describe "Remove-FoldersRecursively_2" {	
	Context "When module is invoked with a basePath that does NOT exist" {

		Import-Module "$baseModulePath\$sut"	
		Mock -ModuleName $sut Confirm-Path { return 1 }
		$testBasePath = "$TestDrive\NonExistentPath\"
				
		$result = ""
		try {
			$result = Remove-FoldersRecursively -basePath $testBasePath -deleteIncludePaths @("bin")
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

Describe "Remove-FoldersRecursively_3" {
	Context "When a valid basePath includes paths to delete" {
		
		Import-Module "$baseModulePath\$sut"
		#Here we get the TestDrive using pesters $TestDrive variable which holds the full file system location to the temporary PSDrive. 
		New-Item -Name "bin" -Path $TestDrive -ItemType Directory
		$testBasePath = "$TestDrive"
		
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Searching for paths to delete, recursively from: $testBasePath"
        }		
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Cleaning: $testBasePath\bin"
        }			
		$result = ""
		try {				
			$result = Remove-FoldersRecursively -basePath $testBasePath -deleteIncludePaths @("bin")
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}

		It "Should search the basePath recursively for paths to delete" {
			Assert-VerifiableMocks
		}		
		
		It "Should delete all matching paths" {
			$pathExists = Test-Path ("$TestDrive\bin")
			$pathExists | Should Be $False
		}
		
		It "Should exit the module with code 0" {
            $result | Should Be 0
        }
	}
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


