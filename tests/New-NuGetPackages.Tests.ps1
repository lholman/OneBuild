$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-NuGetPackages_1" {

	Context "When there are NO NuSpec file(s)" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles { return $null }
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "No NuGet '.nuspec' file found matching the packaging naming convention, exiting without NuGet packaging."
        }
		
		$result = 0
		try {
			$result = New-NuGetPackages -versionNumber "1.0.0"
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}

		It "Should call Get-AllNuSpecFiles once to get array of NuSpec files" {
            Assert-MockCalled Get-AllNuSpecFiles -ModuleName $sut -Times 1
        }
		
		It "Write a descriptive warning" {
			Assert-VerifiableMocks
		}

        It "Exit module with code 0" {
            $result | Should Be 0
        }		
	}	
	
	Context "When there is one NuSpec file" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles {return @("one.nuspec")} -Verifiable
		Mock -ModuleName $sut Invoke-NuGetPack {return 0} -Verifiable
		
		$result = 0
		try {
			$result = New-NuGetPackages -versionNumber "1.0.0"
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Get-AllNuSpecFiles once to get a single NuSpec file" {
            Assert-MockCalled Get-AllNuSpecFiles -ModuleName $sut -Times 1
        }
		It "Should call Invoke-NuGetPack once to generate NuGet package" {
            Assert-MockCalled Invoke-NuGetPack -ModuleName $sut -Times 1
        }
        It "Exits module with code 0" {
			$result | Should Be 0
        }		
	}
	
	Context "When includeSymbolsPackage switch parameter is passed" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles {return @("one.nuspec")} -Verifiable
		Mock -ModuleName $sut Invoke-NuGetPackWithSymbols {return 0} -Verifiable
		
		$result = 0
		try {
			$result = New-NuGetPackages -versionNumber "1.0.0" -includeSymbolsPackage
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Invoke-NuGetPackWithSymbols to generate NuGet and Symbols package" {
            Assert-MockCalled Invoke-NuGetPackWithSymbols -ModuleName $sut -Times 1
        }
        It "Exits module with code 0" {
            $result | Should Be 0
        }		
	}

	Context "When there is an error generating a NuGet package" {
		
		Import-Module "$baseModulePath\$sut"
		#Here we get the TestDrive using pesters $TestDrive variable which holds the full file system location to the temporary PSDrive and generate an empty .nuspec file.
		New-Item -Name "test_error.nuspec" -Path $TestDrive -ItemType File
		$testBasePath = "$TestDrive"	
		Mock -ModuleName $sut Write-Error {} -Verifiable -ParameterFilter {
            $Message -eq "Whilst executing NuGet Pack on spec file $testBasePath\test_error.nuspec, NuGet.exe exited with error message: Root element is missing."
        }
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -like "Attempting to build package from 'test_error.nuspec'. Root element is missing."
        }		
		
		$result = 0
		try {
			$result = New-NuGetPackages -versionNumber "1.0.0" -basePath $testBasePath
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
}
Describe "New-NuGetPackages_2" {
	Context "When there are 2 NuSpec files" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles {return @("one.nuspec", "two.nuspec")}
		Mock -ModuleName $sut Invoke-NuGetPack {} 
		
		$result = 0
		try {
			$result = New-NuGetPackages -versionNumber "1.0.0"
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Invoke-NuGetPack twice to generate both NuGet packages" {
            Assert-MockCalled Invoke-NuGetPack -ModuleName $sut -Times 2
        }

        It "Exits module with code 0" {
            $result | Should Be 0
        }		
	}	
	
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


