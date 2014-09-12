$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Remove-FoldersRecursively_1" {		
	Context "When module is invoked with NO basePath parameter" {
		
		Import-Module "$baseModulePath\$sut"
		#Calling script is the root of the OneBuild folder, where Invoke-Build invokes pester

		$testBasePath = Join-Path "$here" "\.." -Resolve
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Searching for paths to delete, recursively from: $testBasePath"
        }
		$result = ""
		try {
			$result = Remove-FoldersRecursively -deleteIncludePath @("bin")
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should set the path to the calling scripts path" {
			Assert-VerifiableMocks
		}
		
		It "Should exit the module with code 0" {
            $result | Should Be 0
        }		
	}
}

Describe "Remove-FoldersRecursively_2" {		
	Context "When module is invoked with empty deleteIncludePath parameter" {
		
		Import-Module "$baseModulePath\$sut"
		#Calling script is the root of the OneBuild folder, where Invoke-Build invokes pester

		$testBasePath = Join-Path "$here" "\.." -Resolve
		Mock -ModuleName $sut Write-Output {} -Verifiable -ParameterFilter {
            $Object -like "*Cannot validate argument on parameter 'deleteIncludePaths'*."
        }
		Write-Host $Object
		$result = ""
		try {
			$result = Remove-FoldersRecursively -deleteIncludePaths @()
		}
		catch {
			#throw
		}
		finally {
			Write-Host "result: $result"
			Remove-Module $sut
		}
		
		It "Should write a descriptive error" {
			Assert-VerifiableMocks
		}		
	}
}

Describe "Remove-FoldersRecursively_3" {	
	Context "When module is invoked with a basePath that does NOT exist" {

		Import-Module "$baseModulePath\$sut"	
		$testBasePath = "$TestDrive\NonExistentPath\"
		Mock -ModuleName $sut Write-Error {} -Verifiable -ParameterFilter {
            $Message -eq "Supplied basePath: $testBasePath does not exist."
        }
				
		$result = ""
		try {
			$result = Remove-FoldersRecursively -basePath $testBasePath -deleteIncludePath @("bin")
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

Describe "Remove-FoldersRecursively_4" {
	Context "When module is invoked with a basePath that DOES exist" {
		
		Import-Module "$baseModulePath\$sut"
		#Here we get the TestDrive using pesters $TestDrive variable which holds the full file system location to the temporary PSDrive. 
		$testBasePath = "$TestDrive"
		
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Searching for paths to delete, recursively from: $testBasePath"
        }		
		
		$result = ""
		try {
			$result = Remove-FoldersRecursively -basePath $testBasePath -deleteIncludePath @("bin")
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
		
		It "Should exit the module with code 0" {
            $result | Should Be 0
        }		
		
	}
}

Describe "Remove-FoldersRecursively_5" {
	Context "When valid basePath includes paths to delete" {
		
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
			

			$result = Remove-FoldersRecursively -basePath $testBasePath -deleteIncludePath @("bin")
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}

		It "Should set the path to the supplied basePath parameter value" {
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


