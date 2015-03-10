$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-CompiledSolution MSBuild installation" {

		New-Item -Name "Windows" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET" -Path $TestDrive -ItemType Directory

	Context "When a 64-bit .NET framework is NOT installed" {
	
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-CompiledSolution -windowsPath "$TestDrive\Windows" -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "Error executing New-CompiledSolution: No 64-bit .NET Framework \(C:\\Windows\\Microsoft.NET\\Framework64\) installation found on the local system. OneBuild assumes a 64-bit Windows OS install. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues" 	
			$result | Should Match $expectedErrorMessage
		}	
		
	}
		
	Context "When MSBuild is installed" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Windows\Microsoft.NET\Framework64" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET\Framework64\v2.0.50727" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Windows\Microsoft.NET\Framework64\v2.0.50727\msbuild.exe" -Path $TestDrive -ItemType File 
		$testBasePath = "$TestDrive"	
		
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { } -Verifiable -ParameterFilter {
            $msbuildPath -eq "$testBasePath\Windows\Microsoft.NET\Framework64\v2.0.50727\msbuild.exe"}		
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
			
		try {
			New-CompiledSolution -windowsPath "$testBasePath\Windows" -verbose
		}
		catch {
			throw $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Invoke-MsBuildCompilationForSolution is invoked with the correct msbuild path" {
			Assert-VerifiableMocks
		}	
	}

	Context "When MSBuild is NOT installed" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Windows\Microsoft.NET\Framework64" -Path $TestDrive -ItemType Directory
		
		$result = $null
		try {
			$result = New-CompiledSolution -windowsPath "$TestDrive\Windows" -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No known version of MSBuild installed on the local system. Please install MSBuild and try running OneBuild again. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}	
	}
	

}

Describe "New-CompiledSolution Select MSBuild version" {
	
	Context "When there are multiple versions of pre-VS 2013 MSBuild available" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Windows" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET\Framework64" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET\Framework64\v2.0.50727" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Windows\Microsoft.NET\Framework64\v2.0.50727\msbuild.exe" -Path $TestDrive -ItemType File 
		New-Item -Name "Windows\Microsoft.NET\Framework64\v4.0.30319" -Path $TestDrive -ItemType Directory			
		New-Item -Name "Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe" -Path $TestDrive -ItemType File 
		
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { } -Verifiable -ParameterFilter {
            $msbuildPath -eq "$TestDrive\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"}		

		try {
			New-CompiledSolution -windowsPath "$TestDrive\Windows" -verbose
		}
		catch {
			throw $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Invoke-MsBuildCompilationForSolution is invoked with the latest version of MSBuild" {
			Assert-VerifiableMocks
		}
		
	}	

		
	#Context ""
	#Context "When not running on a 64 bit version of Windows"
	#Context "When not running on 64 bit architecture??"
	#Context "When pre and post 2013 MSBuild installed"
	
}

Describe "New-CompiledSolution check for solution file" {
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
			$result = New-CompiledSolution -verbose
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
			$result = New-CompiledSolution -verbose
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

<#
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
#>

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


