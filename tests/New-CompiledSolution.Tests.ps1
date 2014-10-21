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
		
		$result = ""
		try {
			$result = New-CompiledSolution
		}
		catch {
			$result = "$_."
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating  error" {
			$result | Should Match "No solution file found to compile, use the -path parameter if the target solution file isn't in the solution root"
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
		
		$result = ""
		try {
			$result = New-CompiledSolution -path $testBasePath
		}
		catch {
			$result = "$_."
		}
		finally {
			Remove-Module $sut
		}
		
		$exceptionMessage = "MsBuild.exe exited with error message"
		It "Exits the module with a descriptive terminating error" {
			$result | Should Match $exceptionMessage
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


