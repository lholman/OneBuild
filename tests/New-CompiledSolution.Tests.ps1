$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-CompiledSolution" {
	Context "When there is a solution file" {
	
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { }
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "Using Configuration mode 'Release'. Modify this by passing in a value for the parameter '-configMode'"
        }
		
		$result = 0
		try {
			$result = New-CompiledSolution
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Restore-SolutionNuGetPackages to restore the solution NuGet packages" {
            Assert-MockCalled Restore-SolutionNuGetPackages -ModuleName $sut -Times 1
        }
		
		It "Should call Invoke-MsBuildCompilationForSolution to compile the solution with MSBuild" {
            Assert-MockCalled Invoke-MsBuildCompilationForSolution -ModuleName $sut -Times 1
        }	

		It "Should write a descriptive warning about configuration mode" {
			Assert-VerifiableMocks 
		}	
	}
	
	Context "When there is NO solution file" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-FirstSolutionFile { return $null }
		Mock -ModuleName $sut Write-Error {} -Verifiable -ParameterFilter {
            $Message -eq "No solution (*.sln) file found to compile."
        }
		
		$result = 0
		try {
			$result = New-CompiledSolution
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Writes a descriptive error" {
			Assert-VerifiableMocks
		}

        It "Exits module with code 1" {
            $result | Should Be 1
        }		
	}
}
Describe "New-CompiledSolution_2" {	
	Context "When there is an error compiling a solution file" {
		
		Import-Module "$baseModulePath\$sut"
		#Here we get the TestDrive using pesters $TestDrive variable which holds the full file system location to the temporary PSDrive and generate an empty Visual Studio (.sln) file.
		New-Item -Name "test_error.sln" -Path $TestDrive -ItemType File
		$testBasePath = "$TestDrive"	
		
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "Using Configuration mode 'Release'. Modify this by passing in a value for the parameter '-configMode'"
        }		
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "Building '$($TestDrive)\test_error.sln' in 'Release' mode"
        }	
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { return $null }		
		Mock -ModuleName $sut Write-Error {} -Verifiable -ParameterFilter {
            $Message -eq "Whilst executing MsBuild for solution file $testBasePath\test_error.sln, MsBuild.exe exited with error message: Root element is missing."
        }
		
		$result = 0
		try {
			$result = New-CompiledSolution -path $testBasePath
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}

		It "Should return a meaningful error message and write output to host" {
			Assert-VerifiableMocks
		}
		
        It "Exits module with code 1" {
            $result | Should Be 1
        }		
	}	

	Context "When there is an error restoring NuGet packages for a solution file" {	
        $result = 0
		
		It "Exits module with code 1" {
            $result | Should Be 1
        }		
	}
	Context "When setting -configMode the solution is built in that configuration mode" {	
        $result = 0
		
		It "Exits module with code 1" {
            $result | Should Be 1
        }		
	}	
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


