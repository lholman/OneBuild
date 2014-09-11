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

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


