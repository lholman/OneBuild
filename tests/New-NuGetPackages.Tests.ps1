$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-NuGetPackages_NoFiles" {

	Context "When there are NO NuSpec file(s)" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles { return $null }
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "No NuGet '.nuspec' file found matching the packaging naming convention, exiting without NuGet packaging."
        }

		try {
			New-NuGetPackages -versionNumber "1.0.0"
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
	}
}
	
Describe "New-NuGetPackages_OneFile" {
	Context "When there is one NuSpec file" {
		
		Import-Module "$baseModulePath\$sut"
        Mock -ModuleName $sut Get-AllNuSpecFiles {return @("one.nuspec")} -Verifiable
		Mock -ModuleName $sut Invoke-NuGetPack {return 0} -Verifiable

		try {
			New-NuGetPackages -versionNumber "1.0.0"
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
	}
}

Describe "New-NuGetPackages_Symbols" {	
	Context "When includeSymbolsPackage switch parameter is passed" {
		
		Import-Module "$baseModulePath\$sut"
        Mock -ModuleName $sut Get-AllNuSpecFiles {return @("one.nuspec")} -Verifiable
		Mock -ModuleName $sut Invoke-NuGetPackWithSymbols {return 0} -Verifiable
		
		try {
			New-NuGetPackages -versionNumber "1.0.0" -includeSymbolsPackage
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
	}
}

Describe "New-NuGetPackages_Errors" {	
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
		Mock -ModuleName $sut Set-NuGetPath { return "Return_value_does_not_matter_for_this_test" }		
		
		$result = ""
		try {
			$result = New-NuGetPackages -versionNumber "1.0.0" -path $testBasePath
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
        It "Exits the module with a descriptive terminating error" {
            $result | Should Match "An unexpected error occurred whilst executing Nuget Pack for the .nuspec file"
        }		
	}		
}

Describe "New-NuGetPackages_2" {
	Context "When there are 2 NuSpec files" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles {return @("one.nuspec", "two.nuspec")}
		Mock -ModuleName $sut Invoke-NuGetPack {} 
		
		try {
			New-NuGetPackages -versionNumber "1.0.0"
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

	}	
	
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}