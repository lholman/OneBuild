$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-NuGetPackagesForConfig_1" {

	Context "When there are NO NuSpec file(s)" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllConfigTemplateNuSpecFiles { return $null }
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "No NuGet '.nuspec' configuration template file(s) found matching the packaging naming convention, exiting without NuGet packaging."
        }
		
		$result = 0
		try {
			$result = New-NuGetPackagesForConfig -versionNumber "1.0.0"
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}

		It "Should call Get-AllConfigTemplateNuSpecFiles once to get array of NuSpec files" {
            Assert-MockCalled Get-AllConfigTemplateNuSpecFiles -ModuleName $sut -Times 1
        }
		
		It "Write a descriptive warning" {
			Assert-VerifiableMocks
		}

        It "Exit module with code 0" {
            $result | Should Be 0
        }		
	}	
}

Describe "New-NuGetPackages_2" {	
	Context "When there is one NuSpec file" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllConfigTemplateNuSpecFiles {return @("one.configuration.nuspec")} -Verifiable
		#Mock -ModuleName $sut Invoke-NuGetPack {return 0} -Verifiable
		Mock -ModuleName $sut Get-AllConfigTemplateNuSpecFiles {} 
		
		$result = 0
		try {
			$result = New-NuGetPackagesForConfig -versionNumber "1.0.0"
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Get-AllConfigTemplateNuSpecFiles once" {
            Assert-MockCalled Get-AllConfigTemplateNuSpecFiles -ModuleName $sut -Times 1
        }

        It "Exits module with code 0" {
			$result | Should Be 0
        }		
	}
	
}

Describe "New-NuGetPackages_3" {
	Context "When NuSpec files contain 'configuration' in the name" {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "test.nuspec" -Path $TestDrive -ItemType File
		New-Item -Name "test.configuration.nuspec" -Path $TestDrive -ItemType File
		New-Item -Name "testconfiguration.nuspec" -Path $TestDrive -ItemType File
		New-Item -Name "Configuration.Test.nuspec" -Path $TestDrive -ItemType File		
		$testBasePath = "$TestDrive"
		Mock -ModuleName $sut Get-AllConfigTemplateNuSpecFiles {} 
		
		$result = 0
		try {
			$result = New-NuGetPackagesForConfig -versionNumber "1.0.0" -path $testBasePath
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Get-AllConfigTemplateNuSpecFiles once" {
            Assert-MockCalled Get-AllConfigTemplateNuSpecFiles -ModuleName $sut -Exactly 1
        }
		
		It "Should call Get-AllClientsForTemplateNuSpecFile for each " {
            Assert-MockCalled Get-AllClientsForTemplateNuSpecFile -ModuleName $sut -Exactly 3
        }		

        It "Exits module with code 0" {
            $result | Should Be 0
        }		
	}	
}

Context "Next" {

}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


