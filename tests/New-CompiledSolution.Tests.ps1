$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-CompiledSolution No MSBuild" {

	Context "When NO (64-bit) .NET Framework or Visual Studio versions are installed" {
	
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-CompiledSolution -windowsPath $TestDrive -programFilesx86Path $TestDrive -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No 64-bit .NET Framework \(C:\\Windows\\Microsoft.NET\\Framework64\) or 64-bit Visual Studio \(C:\\Program Files \(x86\)\\MSBuild\) installation of MSBuild found on the local system. OneBuild assumes a 64-bit Windows OS install. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues" 	
			$result | Should Match $expectedErrorMessage
		}	
		
	}

}

Describe "New-CompiledSolution .NET Framework MSBuild" {

		New-Item -Name "Windows" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET" -Path $TestDrive -ItemType Directory
		
	Context "When a single .NET Framework MSBuild version is installed" {
	
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
			New-CompiledSolution -windowsPath "$testBasePath\Windows" -programFilesx86Path $TestDrive -verbose
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

}

Describe "New-CompiledSolution Select .NET Framework MSBuild version" {
	
	Context "When there are multiple .NET Framework MSBuild versions installed" {
	
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
			New-CompiledSolution -windowsPath "$TestDrive\Windows" -programFilesx86Path $TestDrive -verbose
		}
		catch {
			throw $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Invoke-MsBuildCompilationForSolution is invoked with the latest .NET Framework MSBuild version" {
			Assert-VerifiableMocks
		}
		
	}	

		
	#Context "When not running on a 64 bit version of Windows"
	#Context "When not running on 64 bit architecture??"
	#Context "When pre and post 2013 MSBuild installed"
	
}
	
Describe "New-CompiledSolution Visual Studio MSBuild" {

	Context "When a single Visual Studio MSBuild version is installed" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Program Files (x86)" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild\12.0\" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin\amd64" -Path $TestDrive -ItemType Directory			
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin\amd64\msbuild.exe" -Path $TestDrive -ItemType File 
		$testBasePath = "$TestDrive"	
		
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { } -Verifiable -ParameterFilter {
            $msbuildPath -eq "$TestDrive\Program Files (x86)\MSBuild\12.0\bin\amd64\msbuild.exe"}		
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
			
		try {
			New-CompiledSolution -programFilesx86Path "$testBasePath\Program Files (x86)" -verbose
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
}

Describe "New-CompiledSolution Select Visual Studio MSBuild version" {
	
	Context "When there are multiple Visual Studio MSBuild versions installed" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Program Files (x86)" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild\12.0\" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin\amd64" -Path $TestDrive -ItemType Directory			
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin\amd64\msbuild.exe" -Path $TestDrive -ItemType File 
		New-Item -Name "Program Files (x86)\MSBuild\13.0\" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild\13.0\bin" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Program Files (x86)\MSBuild\13.0\bin\amd64" -Path $TestDrive -ItemType Directory			
		New-Item -Name "Program Files (x86)\MSBuild\13.0\bin\amd64\msbuild.exe" -Path $TestDrive -ItemType File
		New-Item -Name "Program Files (x86)\MSBuild\Microsoft\" -Path $TestDrive -ItemType Directory 		
		$testBasePath = "$TestDrive"	
		
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { } -Verifiable -ParameterFilter {
            $msbuildPath -eq "$TestDrive\Program Files (x86)\MSBuild\13.0\bin\amd64\msbuild.exe"}		
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
			
		try {
			New-CompiledSolution -programFilesx86Path "$testBasePath\Program Files (x86)" -verbose
		}
		catch {
			throw $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Invoke-MsBuildCompilationForSolution is invoked with the latest Visual Studio MSBuild version" {
			Assert-VerifiableMocks
		}	
	}	
	
}

Describe "New-CompiledSolution" {

	Context "When there are .NET Framework and Visual Studio MSBuild versions installed" {
	
		#Implementation
	
		It "Invoke-MsBuildCompilationForSolution is invoked with the latest Visual Studio MSBuild version" {
			Assert-VerifiableMocks
		}		
	
	}

}
<#
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


