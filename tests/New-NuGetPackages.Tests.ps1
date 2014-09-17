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
		
		It "Writes a descriptive warning" {
			Assert-VerifiableMocks
		}

        It "Exits module with code 0" {
            $result | Should Be 0
        }		
	}	
	
	Context "When there is one NuSpec file" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles {} -Verifiable
		Mock -ModuleName $sut Invoke-NuGetPack {} -Verifiable
		
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
		It "Should call Invoke-NuGetPack once to generate NuGet package" {
            Assert-MockCalled Invoke-NuGetPack -ModuleName $sut -Times 1
        }
        It "Exits module with code 0" {
			$result | Should Be 0
        }		
	}
	
	Context "When there is one NuSpec file and includeSymbolPackage switch parameter is passed" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles {} -Verifiable
		Mock -ModuleName $sut Invoke-NuGetPackWithSymbols {} -Verifiable
		
		$result = 0
		try {
			$result = New-NuGetPackages -versionNumber "1.0.0" -includeSymbolPackage
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
		It "Should call Invoke-NuGetPackWithSymbols once to generate NuGet package" {
            Assert-MockCalled Invoke-NuGetPackWithSymbols -ModuleName $sut -Times 1
        }

        It "Exits module with code 0" {
            $result | Should Be 0
        }		
	}
}
Describe "New-NuGetPackages_1" {
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


