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
		
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Get-64BitMsBuildRegistryHive { }

		$result = $null
		try {
			$result = New-CompiledSolution -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No 64-bit .NET Framework \(C:\\Windows\\Microsoft.NET\\Framework64\) or 64-bit Visual Studio \(C:\\Program Files \(x86\)\\MSBuild\) installation of MSBuild found on the local system. OneBuild also assumes a 64-bit Windows OS install. Refer to http://lholman.github.io/OneBuild/conventions.html for more detail. If you require 32-bit Windows OS support please raise an issue at https://github.com/lholman/OneBuild/issues" 	
			$result | Should Match $expectedErrorMessage
		}	
		
	}

}


Describe "New-CompiledSolution .NET Framework MSBuild" {

		New-Item -Name "Windows" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET" -Path $TestDrive -ItemType Directory
		
	Context "When a single .NET Framework MSBuild version is installed" {
	
		Import-Module "$baseModulePath\$sut"
		$windowsPath = $env:windir
		#$programFilesx86Path = ${env:ProgramFiles(x86)}
					
		$msBuildToolsPath = "$windowsPath\Microsoft.NET\Framework64\v3.5\"
		$msBuildExecutablePath = Join-Path -path $msBuildToolsPath -childpath "msbuild.exe"

		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}		
		Mock -ModuleName $sut Get-64BitMsBuildRegistryHive {@(@{PSChildName="3.5";
																Property=@("MSBuildToolsPath");
																PSPath="Microsoft.PowerShell.Core\Registry::HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\3.5"
																})
															}

		Mock -ModuleName $sut Get-ItemProperty {@{MSBuildToolsPath = "C:\windows\Microsoft.NET\Framework64\v3.5\";PSChildName = "3.5"}} -Verifiable -ParameterFilter {$Name -eq "MSBuildToolsPath"}		
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { } -Verifiable -ParameterFilter {$msbuildPath -eq $msBuildExecutablePath}		
		
		try {
			New-CompiledSolution -verbose
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
		$windowsPath = $env:windir
		$msBuildToolsPath = "$windowsPath\Microsoft.NET\Framework64\v4.0.30319\"
		$msBuildExecutablePath = Join-Path -path $msBuildToolsPath -childpath "msbuild.exe"
		
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Get-64BitMsBuildRegistryHive {@(@{PSChildName="4.0";
																Property=@("MSBuildToolsPath");
																PSPath="Microsoft.PowerShell.Core\Registry::HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\4.0"
																}),
															(@{PSChildName="3.5";
																Property=@("MSBuildToolsPath");
																PSPath="Microsoft.PowerShell.Core\Registry::HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\3.5"
																})
															}
		
		Mock -ModuleName $sut Get-ItemProperty {@{MSBuildToolsPath = "C:\windows\Microsoft.NET\Framework64\v4.0.30319\";PSChildName = "4.0"}} -Verifiable -ParameterFilter {$Name -eq "MSBuildToolsPath"}	
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { } -Verifiable -ParameterFilter {
            $msbuildPath -eq $msBuildExecutablePath}			

		try {
			New-CompiledSolution -verbose
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
}



# Context "When .NET Framework Version 2.0 is installed
# It strips it from availabe MSBuild versions

<#%	
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
	
	Context "When there is a non-ToolsVersion child folder under Visual Studio MSBuild parent folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Program Files (x86)" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild\12.0\" -Path $TestDrive -ItemType Directory
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin\amd64" -Path $TestDrive -ItemType Directory			
		New-Item -Name "Program Files (x86)\MSBuild\12.0\bin\amd64\msbuild.exe" -Path $TestDrive -ItemType File 
		New-Item -Name "Program Files (x86)\MSBuild\Microsoft\" -Path $TestDrive -ItemType Directory #An example non-[ToolsVersion] folder 	
		New-Item -Name "Program Files (x86)\MSBuild\Microsoft\Windows Workflow Foundation" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Program Files (x86)\MSBuild\v3.5" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Program Files (x86)\MSBuild\v3.5\msbuild.exe" -Path $TestDrive -ItemType File 		
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
		
		It "Invoke-MsBuildCompilationForSolution is invoked with the latest Visual Studio MSBuild version" {
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
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Windows" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET\Framework64" -Path $TestDrive -ItemType Directory
		New-Item -Name "Windows\Microsoft.NET\Framework64\v2.0.50727" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Windows\Microsoft.NET\Framework64\v2.0.50727\msbuild.exe" -Path $TestDrive -ItemType File 
		New-Item -Name "Windows\Microsoft.NET\Framework64\v4.0.30319" -Path $TestDrive -ItemType Directory			
		New-Item -Name "Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe" -Path $TestDrive -ItemType File 

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
			New-CompiledSolution -programFilesx86Path "$testBasePath\Program Files (x86)" -windowsPath "$TestDrive\Windows" -verbose
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

%#>

Describe "New-CompiledSolution check for solution file" {

	Context "When there is a solution file" {
	
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { }
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { }
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "Using Configuration mode 'Release'. Modify this by passing in a value for the parameter '-configMode'"
        }
		
		try {
			New-CompiledSolution -verbose
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

		It "Should write a descriptive verbose message about configuration mode" {
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

Describe "New-CompiledSolution terminating errors" {	

	Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
		$Message -eq "Using Configuration mode 'Release'. Modify this by passing in a value for the parameter '-configMode'"
	}		
	Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
		$Message -eq "Building '$($TestDrive)\test_error.sln' in 'Release' mode"
	}	
	
	Context "When there is an error compiling a solution file" {
	#Note: This is the *ONLY* test that requires real msbuild.exe on the system, so as to generate a genuine error.
		
		Import-Module "$baseModulePath\$sut"

		New-Item -Name "test_error.sln" -Path $TestDrive -ItemType File
		$testBasePath = "$TestDrive"	
		
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { return $null }		
		
		$result = ""
		try {
			$result = New-CompiledSolution -path $testBasePath -verbose
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

}


Describe "New-CompiledSolution terminating errors" {	
	
	Context "When there is an error restoring NuGet packages for an invalid solution file" {	
		Import-Module "$baseModulePath\$sut"
	
		$windowsPath = $env:windir
					
		$msBuildToolsPath = "$windowsPath\Microsoft.NET\Framework64\v3.5\"
		$msBuildExecutablePath = Join-Path -path $msBuildToolsPath -childpath "msbuild.exe"

		New-Item -Name "empty_solution.sln" -Path $TestDrive -ItemType File
		$testBasePath = $TestDrive
		
		Mock -ModuleName $sut Get-64BitMsBuildRegistryHive {@(@{PSChildName="3.5";
																Property=@("MSBuildToolsPath");
																PSPath="Microsoft.PowerShell.Core\Registry::HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\3.5"
																})
															}
		
		Mock -ModuleName $sut Get-ItemProperty {@{MSBuildToolsPath = "C:\windows\Microsoft.NET\Framework64\v3.5\";PSChildName = "3.5"}} -Verifiable -ParameterFilter {$Name -eq "MSBuildToolsPath"}		
		Mock -ModuleName $sut Get-FirstSolutionFile { return "$TestDrive\empty_solution.sln"}
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution { }
		
		$result = $null
		try {
			$result = New-CompiledSolution -verbose
		}
		catch {
			$result = "$_."
		}
		finally {
			Remove-Module $sut
		}
		
		$exceptionMessage = "No file format header found."
		It "Exits the module with a descriptive terminating error" {
			$result | Should Match $exceptionMessage
		}	

		It "Will attempt to restore NuGet packages for the invalid solution file" {
			Assert-VerifiableMocks 
		}	
		
	}	
	
}


Describe "New-CompiledSolution configMode" {		
	Context "When setting -configMode to Debug" {	
		
		Import-Module "$baseModulePath\$sut"

		Mock -ModuleName $sut Get-LatestInstalled64BitMSBuildPathFromRegistry { return "NotNull" }
		Mock -ModuleName $sut Get-FirstSolutionFile { return "solution.sln"}
		Mock -ModuleName $sut Restore-SolutionNuGetPackages { return $null }	
		Mock -ModuleName $sut Invoke-MsBuildCompilationForSolution -Verifiable -ParameterFilter { $configMode -eq "Debug" }	
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "Using Configuration mode 'Debug'. Modify this by passing in a value for the parameter '-configMode'"
        }		
		
		try {
			New-CompiledSolution -configMode "Debug" -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Will invoke MSBuild with a Debug configuration" {
			Assert-VerifiableMocks 
		}			
	}	
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


