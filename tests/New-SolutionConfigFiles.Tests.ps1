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
		New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"	
		Mock -ModuleName $sut Get-ChildConfigFolders { return "$testBasePath\Project1\_config"}
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
		
		It "Should call Get-ChildConfigFolders to identify all _config folders under path" {
            Assert-MockCalled Get-ChildConfigFolders -ModuleName $sut -Times 1
        }
		
		It "Should call New-ConfigTransformsForConfigPath once" {
            Assert-MockCalled New-ConfigTransformsForConfigPath -ModuleName $sut -Times 1
        }

	}
	
	Context "When there is NO configuration to transform" {
	
		Import-Module "$baseModulePath\$sut"

		Mock -ModuleName $sut Get-ChildConfigFolders { return $null}
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "No configuration '_config' folders found, exiting without configuration  transformation."
        }
				
		try {
			New-SolutionConfigFiles -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Write a descriptive warning" {
			Assert-VerifiableMocks
		}
		

	}	
	
}

Describe "New-SolutionConfigFiles one _config folder" {

	Context "When there is one _config folder under the path folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory	
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
		
		It "Should identify one _config folder" {
            #Assert-MockCalled Get-ChildConfigFolders -ModuleName $sut -Times 1
        }
		
		It "Should call New-ConfigTransformsForConfigPath once" {
            Assert-MockCalled New-ConfigTransformsForConfigPath -ModuleName $sut -Times 1
        }

	}
	
}

Describe "New-SolutionConfigFiles multiple _config folders" {

	Context "When there are multiple _config folders under the path folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project2" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project2\_config" -Path $TestDrive -ItemType Directory		
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

Describe "New-SolutionConfigFiles application configuration" {

	Context "When there is an application folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\source.xml" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"	
		Mock -ModuleName $sut Confirm-BaseConfigFileExistsForConfigPath { } -Verifiable
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Confirm-BaseConfigFileExistsForConfigPath once" {
            Assert-MockCalled Confirm-BaseConfigFileExistsForConfigPath -ModuleName $sut -Times 1
        }

	}	
}

Describe "New-SolutionConfigFiles application configuration" {
	
	New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
	New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory	
	$testBasePath = "$TestDrive"	

	Context "When there is NO application folder" {
	
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path "$testBasePath\Project1" -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No 'application' folder found under path: $testBasePath\Project1\_config, please remove the _config folder or add a child 'application' folder." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}

	}	
	
	Context "When there is NO base config file" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path "$testBasePath\Project1" -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No XML base config file found under path: $testBasePath\Project1\_config\application, please remove the '_config\application' folder or add a base XML config file." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}

	}		
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


