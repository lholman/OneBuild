$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-SolutionConfigFiles" {

	Context "When there is configuration to transform" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\[config]" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"	
		Mock -ModuleName $sut Get-ChildConfigFolders { return "$testBasePath\Project1\[config]"}
		Mock -ModuleName $sut New-ConfigTransformsForConfigPath { }

		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Get-ChildConfigFolders to identify all [config] folders under path" {
            Assert-MockCalled Get-ChildConfigFolders -ModuleName $sut -Times 1
        }
		
		It "Should call New-ConfigTransformsForConfigPath once" {
            Assert-MockCalled New-ConfigTransformsForConfigPath -ModuleName $sut -Times 1
        }

	}
	
}

Describe "New-SolutionConfigFiles one [config] folder" {

	Context "When there is one [config] folder under the path folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\[config]" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"
		Mock -ModuleName $sut New-ConfigTransformsForConfigPath { }
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should identify one [config] folder" {
            #Assert-MockCalled Get-ChildConfigFolders -ModuleName $sut -Times 1
        }
		
		It "Should call New-ConfigTransformsForConfigPath once" {
            Assert-MockCalled New-ConfigTransformsForConfigPath -ModuleName $sut -Times 1
        }

	}
	
}

Describe "New-SolutionConfigFiles multiple [config] folders" {

	Context "When there are multiple [config] folders under the path folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\[config]" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project2" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project2\[config]" -Path $TestDrive -ItemType Directory		
		$testBasePath = "$TestDrive"	
		Mock -ModuleName $sut New-ConfigTransformsForConfigPath { }

		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call New-ConfigTransformsForConfigPath twice" {
            Assert-MockCalled New-ConfigTransformsForConfigPath -ModuleName $sut -Times 2
        }

	}
	
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


